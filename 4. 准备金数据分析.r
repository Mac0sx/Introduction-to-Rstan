# ===========================================================   
# 4. ����������׼����������ϣ�
# year: �¹���
# ay: �¹��꣨�򻯣�
# lag: ��չ��
# cum: �ۻ����
# incre: �������
# premium�����ձ���
# =========================================================== 
# ��ȡ���ݿ��ʽ������
  library(data.table)
  library(gamlss)
# ����Ԥ�������
  dtnew = fread("F:\\Files\\ѧ���о�\\��������\\��Ҷ˹�ع�ģ�ͣ����+���룩//triangle data(���ݿ��ʽ).csv")  
  Xpred <- model.matrix(~ factor(ay) + factor(lag), data = dtnew)  # ��ƾ���
# ���ڽ�ģ������  
  dt <- dtnew[incre>0]
  X <- model.matrix(~ factor(ay) + factor(lag), data = dt)  # ��ƾ���

# ===========================================================
# 1. Poisson��(���ɻع�ģ��)
# ===========================================================
  m.po <- glm(incre ~ factor(ay) + factor(lag) + offset(log(premium)), data = dt, family = poisson)
# ��׼�������ݽ���Ԥ��
  pred.po <- exp(Xpred%*%coef(m.po))*dtnew$premium
  dtnew$pred.po =  pred.po
  summary(m.po)
  
# ===========================================================
# 2. Bayesian + rtan(���ɻع�ģ��)
# ===========================================================
# ��ƾ���
  library(rstan)
  mydat <- list(N = nrow(X),
                K = ncol(X),
                y = dt$incre,
                premium = dt$premium
  )

  glmod <- "
  data{
    int N;
    int K;
    matrix[N,K] X;   
    int y[N];
    vector[N] premium;
  }
  parameters{
    vector[K] beta; 
  }
  transformed parameters {
    vector[N] mu; 
    vector[N] loglike;
    mu = exp(X * beta + log(premium)); 
    for (i in 1:N){
      loglike[i] = poisson_lpmf(y[i]|mu[i]);
    }    
  }
  model{  
    target += normal_lpdf(beta|0, 100);
    target += loglike;
  }
  "
  sfit <- stan(model_code = glmod, data = mydat,
               pars = c('beta', 'lp__'),
               iter = 10000, warmup = 5000, thin = 5, chains = 4)

# �����������ֵ
  print(sfit, pars = c('beta', 'lp__'),
        probs = c(0.05, 0.5, 0.95))
# ����ع�ϵ��������·��ͼ
  traceplot(sfit, pars = c('beta'), inc_warmup = FALSE)  # �켣ͼ
  stan_ac(sfit, pars = c('beta'), inc_warmup = FALSE)    # �����ͼ
  stan_hist(sfit, pars = c('beta'), inc_warmup = FALSE)  # ����ֲ�ֱ��ͼ

# -----------------------------------------------------------------
# ��ȡ HMC ��������
# Ԥ�������Ǻ������ǵ�����
# -----------------------------------------------------------------
  set.seed(1123)
  beta.mcmc <- extract(sfit, pars = 'beta')$beta
  n_sims <- nrow(beta.mcmc)
  y_rep <- matrix(NA, nrow = nrow(dtnew), ncol = n_sims)
  for (s in 1:n_sims){
    beta <- beta.mcmc[s,]
    mu <- exp(Xpred%*%(beta) + log(dtnew$premium))
    y_rep[, s] <- rPO(nrow(dtnew), mu = mu)
  }
# �������ľ�ֵ��ΪԤ��ֵ
  pred.bayes <- apply(y_rep, 1, mean)
  dtnew$pred.bayes <- pred.bayes

# �Ƚ����ݷ���Bayesian�Ľ��
  plot(pred.po, pred.bayes, xlab = '���ݷ�', ylab = '��Ҷ˹����')
  abline(a = 0, b = 1)

# -----------------------------------------------------------------------------------
# Ԥ��ֲ�
# -----------------------------------------------------------------------------
  ind.lower <- (dtnew$ay + dtnew$lag >10)   # ��ȡ������
  res.mcmc <- apply(y_rep[ind.lower,], 2, sum)
  hist(res.mcmc, xlab = 'δ�����׼����', ylab = 'Ƶ��', main = '')   # δ�����׼�����Ԥ��ֲ���������֮�ͣ�
  