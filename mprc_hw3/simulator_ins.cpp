#include <iostream>
#include <fstream>
#include <map>
#include <vector>
#include <string>
using namespace std;

#define reg_t uint16_t
#define addr_t uint16_t
#define CODE_BASE 0x8000
#define DATA_BASE 0x0000

static void panic(const string& info) {
    cout << info << endl;
    exit(1);
}

const reg_t zero=0;
reg_t regs[16];
#define ip regs[2]
#define sp regs[3]
uint16_t get_reg(const string& name) {
    if (name[0] != '$') panic("get_reg: not a register name " + name);
    if (name == "$zero,") return 0;
    if (name == "$ip,") return 2;
    if (name == "$sp,") return 3;
    if (name[1] == 't') return 4 + name[2] - '0';
    if (name[1] == 's') return 12 + name[2] - '0';
    panic("get_reg: invalid register name " + name);
    return 0xffff;
}

const char wasm_file_name[] = "bubble_sort.wasm";
map<addr_t, uint16_t> binary_file;
map<string, addr_t> symbol_map;
map<addr_t, addr_t> branch_target;
uint16_t count_ins = 0;

bool is_label(const string& s) {
    if (s[s.length() - 1] == ':')
        return true;
    return false;
}

vector<string> split(const string& s, const string& delim_set = " ") {
    size_t last = 0;
    size_t index = s.find_first_of(delim_set, last);
    vector<string> ret;
    while (index != string::npos) {
        if (index != last)
            ret.push_back(s.substr(last, index - last));
        last = index + 1;
        index = s.find_first_of(delim_set, last);
    }
    if (index - last > 0) {
        ret.push_back(s.substr(last, index - last));
    }
    return ret;
}

void print_symbol_map() {
    printf("symbol_map:\n");
    for (auto mitr = symbol_map.begin(); mitr != symbol_map.end(); ++mitr) {
        printf("%s: 0x%04x:\n", mitr->first.c_str(), mitr->second);
    }
}

void generate_symbol_map(const char* filename) {
    addr_t code_pos = CODE_BASE, data_pos = DATA_BASE;
    ifstream fin(filename);
    string buff;
    if (!fin) panic("generate_symbol_map: invalid filename " + string(filename));
    while (fin >> buff) {
        if (buff[0] != '.') panic("generate_symbol_map: unexpected string, missing part definition.");
        if (buff == ".data") {
            while (fin >> buff) {
                if (buff == ".edata")
                    break;
                if (is_label(buff)) {
                    symbol_map[buff.substr(0, buff.length() - 1)] = data_pos;
                    continue;
                }
                if (buff[0] == 'd') {
                    vector<string> params = split(buff, "(,)");
                    uint16_t times = atoi(params[2].c_str());
                    uint16_t value = atoi(params[1].c_str());
                    for (int i = 0; i < times; i++) {
                        data_pos += 2;
                    }
                    continue;
                }
                data_pos += 2;
            }
        }
        else if (buff == ".code") {
            while (fin >> buff) {
                if (buff == ".ecode") {
                    code_pos += 2;
                    break;
                }
                if (is_label(buff)) {
                    symbol_map[buff.substr(0, buff.length() - 1)] = code_pos;
                    continue;
                }
                getline(fin, buff, ',');
                getline(fin, buff, ',');
                fin >> buff;
                code_pos += 2;
            }
        }
        else panic("generate_symbol_map: unexpected part definition " + buff);
    }
}

void wasm(const char* filename, map<addr_t, uint16_t>& binary) {
    generate_symbol_map(filename);
    print_symbol_map();
    addr_t code_pos = CODE_BASE, data_pos = DATA_BASE;
    ifstream fin(filename);
    string buff;
    if (!fin) panic("wasm: invalid filename " + string(filename));
    printf("wasm:\n");
    while (fin >> buff) {
        if (buff[0] != '.') panic("wasm: unexpected string, missing part definition.");
        if (buff == ".data") {
            while (fin >> buff) {
                if (buff == ".edata")
                    break;
                if (is_label(buff)) {
                    symbol_map[buff.substr(0, buff.length() - 1)] = data_pos;
                    continue;
                }
                if (buff[0] == 'd') {
                    vector<string> params = split(buff, "(,)");
                    uint16_t times = atoi(params[2].c_str());
                    uint16_t value = atoi(params[1].c_str());
                    for (int i = 0; i < times; i++) {
                        binary[data_pos] = value;
                        data_pos += 2;
                    }
                    continue;
                }
                binary[data_pos] = atoi(buff.c_str());
                data_pos += 2;
            }
        }
        else if (buff == ".code") {
            while (fin >> buff) {
                if (buff == ".ecode") {
                    binary[code_pos] = 0xffff;
                    code_pos += 2;
                    break;
                }
                if (is_label(buff)) {
                    symbol_map[buff.substr(0, buff.length() - 1)] = code_pos;
                    continue;
                }
                uint16_t code;
                if (buff == "lw") {
                    code = 0x0000;
                }
                else if (buff == "sw") {
                    code = 0x4000;
                }
                else if (buff == "addi") {
                    code = 0x8000;
                }
                else if (buff == "ble") {
                    code = 0xc000;
                }
                else panic("wasm: invalid code " + buff);
                printf("%04x %s ",code_pos, buff.c_str());
                fin >> buff;
                code |= get_reg(buff) << 6;
                cout << buff << ' ';
                fin >> buff;
                code |= get_reg(buff) << 10;
                cout << buff << ' ';
                fin >> buff;
                if (((code&0xc000)==0xc000)&&symbol_map.find(buff) != symbol_map.end()) {
                    int16_t offset = int16_t(symbol_map[buff]) - int16_t(code_pos);
                    offset = (offset & 0x1f)>>1;
                    code |= offset;
                    branch_target[code_pos] = symbol_map[buff];
                    printf("%s: %04x\n", buff.c_str(), symbol_map[buff]);
                }
                else {
                    code |= atoi(buff.c_str());
                    cout << buff << endl;
                }
                binary[code_pos] = code;
                code_pos += 2;
            }
        }
        else panic("wasm: unexpected part definition " + buff);
    }
}

void print_mem(const map<addr_t, uint16_t>& binary, addr_t start=0x0000, addr_t end=0xffff) {
    printf("binary_file from 0x%04x to 0x%04x:\n", start, end);
    for (auto mitr = binary.lower_bound(start); mitr != binary.lower_bound(end); ++mitr) {
        printf("0x%04x: %x\n", mitr->first, mitr->second);
    }
}

void print_regs() {
    printf("registers:\n");
    for (int i = 0; i < 8; i++) {
        cout << regs[i] << ' ';
    }
    cout << endl;
    for (int i = 8; i < 16; i++) {
        cout << regs[i] << ' ';
    }
    cout << endl;
}

void simulator(map<addr_t, uint16_t>& binary) {
    printf("start simulation:\n");
    ip = CODE_BASE;
    sp = DATA_BASE;
    uint16_t code = binary[ip];
    while (code != 0xffff) {
        uint16_t op, rs, rt, imm;
        op = (code>>14)&0x3;
        rs = (code>>10)&0xf;
        rt = (code>>6)&0xf;
        imm = code&0x1f;
        printf("%d %04x\top: %d\trs: %d\trt: %d\timm: %d\n", ++count_ins, ip, op, rs, rt, imm);
        switch (op) {
        case 0:
            regs[rt] = binary[regs[rs]+imm];
            break;
        case 1:
            binary[regs[rs]+imm] = regs[rt];
            print_mem(binary_file, DATA_BASE, CODE_BASE);
            break;
        case 2:
            regs[rt] = regs[rs] + imm;
            break;
        case 3:
            if (regs[rt] <= regs[rs]) ip = branch_target[ip] - 2;
            break;
        default:
            panic("wtf?");
        }
        print_regs();
        ip += 2;
        code = binary[ip];
    }
}

int main() {
    wasm(wasm_file_name, binary_file);
    print_mem(binary_file);
    simulator(binary_file);
    print_mem(binary_file, DATA_BASE, CODE_BASE);
}
