# ===========================================================   
# 3. ��������ģ��(GLM)
# =========================================================== 
# ���������y����٤��ֲ�
# ��ֵ���Ա�ʾΪ����Э���������Ժ���
# ����=5+1.2*x1+1.3*x2+1.4*x3
# ��������Э���������Ӿ�ֵΪ0.1��ָ���ֲ�
# ��ģ1000���������Э�����Ĺ۲�ֵ������������ģ������Ӧ��Rstan�����ع�ģ�͡�
# ģ������

  set.seed(111)
  N <- 1000  #������
# ����Э����
  covariates <- replicate(3, rexp(n = N, rate = 10))  
  colnames(covariates) <- c('x1','x2','x3')
# ��ƾ���
  X <- cbind(Intercept = 1, covariates)
  coefs <- c(5, 1.2, 1.3, 1.4)    # �ع�ϵ������ʵֵ
  mu <- exp(X %*% coefs)         # ������ľ�ֵ����ʵֵ��
  sigma <- 0.2                   # ٤��ֲ�����ɢ����
# ģ��������Ĺ۲�ֵ������٤��ֲ�
  library(gamlss)
  y <- rGA(N, mu = mu, sigma = sigma)  
  dt <- data.frame(y, X)  # ģ������ݼ�
# Ϊ�˱��ڱȽϣ���������Ӧ��glm()�������������ļ�����Ȼ����ֵ���йس����������������¡�
# Ӧ��glm����������������ģ��glmfit
  glmfit <- glm(y ~ x1 + x2 + x3, family = Gamma(link = "log"),data = dt)
  summary(glmfit)                # �����������ֵ
  
# ����Ӧ��rstan����ģ�͵Ĳ��������Ȱ����ݷ�װ��mydat�У�������Ӧ�ı�Ҷ˹ģ�ͼ�Ϊglmod��
  mydat <- list(N = N, K = ncol(X), y = y, X = X)
  
  glmod <- "
  data{
    int N;
    int K;
    matrix[N,K] X;   
    vector[N] y;
  }
  parameters{
    vector[K] beta; 
    real<lower=0> sigma2;
  }
  transformed parameters {
    vector[N] mu; 
    vector[N] loglike;
    real sigma;
    mu = exp(X * beta); 
    sigma = sigma2^0.5;
    for (i in 1:N){
      loglike[i] = gamma_lpdf(y[i]|1/sigma2, 1/(mu[i]*sigma2)); // loglikelihood function
    }    
  }
  model{  
    target += normal_lpdf(beta|0, 100);
    target += cauchy_lpdf(sigma2|0, 5);
    target += loglike;
  }
  "

  sfit <- stan(model_code = glmod, data = mydat,
               pars = c('beta', 'sigma', 'lp__'),
               iter = 1000, warmup = 200, thin = 2, chains = 4)
# �����������ֵ
  print(sfit, pars = c('beta', 'sigma', 'lp__'),
        probs = c(0.05, 0.5, 0.95))
# ����ع�ϵ��������·��ͼ
  traceplot(sfit, pars = c('beta', 'sigma'), inc_warmup = FALSE)  # �켣ͼ
  stan_ac(sfit, pars = c('beta', 'sigma'), inc_warmup = FALSE)    # �����ͼ