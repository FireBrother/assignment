function k = my_kernel(X1, X2, sigma)
    k = exp(-0.5/(sigma.^2)*(norm(X1-X2,2).^2));
end
