# ===========================================================  
# 2. ���Իع�ģ��(LM)
# ===========================================================  
# ����8 4�� 
# ����y������̬�ֲ�����׼��Ϊ2
# ��ֵ���Ա�ʾΪ����Э���������Ժ���
# ����=10+0.2*x1-0.3*x2+0.4*x3
# ��������Э���������ӱ�׼��̬�ֲ�
# ��ģ1000���������Э�����Ĺ۲�ֵ
# ����������ģ������Ӧ��Rstan�������Իع�ģ��
# -----------------------------------------------------------
# ģ������
  set.seed(111)
  N <- 1000  #������
# ����Э����
  covariates <- replicate(3, rnorm(n = N))  
  colnames(covariates) <- c('x1', 'x2', 'x3')
# ��ƾ���
  X <- cbind(Intercept = 1, covariates)
  coefs <- c(10, 0.2, -0.3, 0.4)  #�ع�ϵ������ʵֵ
  mu <- X %*% coefs #������ľ�ֵ����ʵֵ��
  sigma <- 2  #������ı�׼��
  y <- rnorm(N, mu, sigma)  
  dt <- data.frame(y, X)  #ģ������ݼ�
  fit <- lm(y ~ x1 + x2 + x3, data = dt)
  summary(fit)

# rstan ��� - vector��ʽ
  mydat <- list(N = N, K = ncol(X), y = y, X = X)  #��list��װ����
  lmod <-"
  data{
    int N;
    int K;
    matrix[N,K] X;
    vector[N] y;
  }
  
  parameters{
    vector[K] beta; 
    real<lower = 0> sigma;
  }
  
  model{
    vector[N] mu;
    mu = X * beta;   
    target += normal_lpdf(beta|0, 100);
    target += cauchy_lpdf(sigma|0, 5);
    target += normal_lpdf(y|mu, sigma);
  }
  "
  sfit <- stan(model_code = lmod, 
               data = mydat, 
               iter = 2000, warmup = 200, thin = 2, chains = 4)
  
  print(sfit, probs = c(0.05, 0.5, 0.95))
  #����ع�ϵ��������·��ͼ
  traceplot(sfit, pars = c('beta', 'sigma'), inc_warmup = FALSE)  # �켣ͼ
  stan_ac(sfit, pars = c('beta', 'sigma'), inc_warmup = FALSE)    # �����ͼ