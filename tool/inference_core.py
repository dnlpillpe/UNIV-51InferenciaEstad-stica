"""Réplica en Python puro del motor inferencial de la app (lib/domain/stats).

Mismos algoritmos que la versión Dart:
  * CDF normal: Hart 5666 (West, 2005), precisión ~1e-14.
  * Cuantil normal: Acklam + un paso de Halley.
  * CDF t de Student: beta incompleta regularizada (fracción continua de Lentz).
  * Cuantil t: bisección sobre la CDF.

Se usa en CI (sin Flutter) para verificar las cifras que afirma el contenido.
No depende de numpy ni scipy.
"""
import math

SQRT2PI = math.sqrt(2 * math.pi)


# ---------------------------------------------------------------- normal
def normal_pdf(x):
    return math.exp(-0.5 * x * x) / SQRT2PI


def normal_cdf(x):
    ax = abs(x)
    if ax > 37:
        c = 0.0
    else:
        e = math.exp(-ax * ax / 2)
        if ax < 7.07106781186547:
            b = 3.52624965998911e-02 * ax + 0.700383064443688
            b = b * ax + 6.37396220353165
            b = b * ax + 33.912866078383
            b = b * ax + 112.079291497871
            b = b * ax + 221.213596169931
            b = b * ax + 220.206867912376
            c = e * b
            b = 8.83883476483184e-02 * ax + 1.75566716318264
            b = b * ax + 16.064177579207
            b = b * ax + 86.7807322029461
            b = b * ax + 296.564248779674
            b = b * ax + 637.333633378831
            b = b * ax + 793.826512519948
            b = b * ax + 440.413735824752
            c = c / b
        else:
            b = ax + 0.65
            b = ax + 4 / b
            b = ax + 3 / b
            b = ax + 2 / b
            b = ax + 1 / b
            c = e / b / 2.506628274631
    return 1 - c if x > 0 else c


_A = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
      1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
_B = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
      6.680131188771972e+01, -1.328068155288572e+01]
_C = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
      -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
_D = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
      3.754408661907416e+00]


def normal_quantile(p):
    if p <= 0 or p >= 1:
        raise ValueError("p fuera de (0,1)")
    plow = 0.02425
    if p < plow:
        q = math.sqrt(-2 * math.log(p))
        x = (((((_C[0]*q+_C[1])*q+_C[2])*q+_C[3])*q+_C[4])*q+_C[5]) / \
            ((((_D[0]*q+_D[1])*q+_D[2])*q+_D[3])*q+1)
    elif p <= 1 - plow:
        q = p - 0.5
        r = q * q
        x = (((((_A[0]*r+_A[1])*r+_A[2])*r+_A[3])*r+_A[4])*r+_A[5])*q / \
            (((((_B[0]*r+_B[1])*r+_B[2])*r+_B[3])*r+_B[4])*r+1)
    else:
        q = math.sqrt(-2 * math.log(1 - p))
        x = -(((((_C[0]*q+_C[1])*q+_C[2])*q+_C[3])*q+_C[4])*q+_C[5]) / \
            ((((_D[0]*q+_D[1])*q+_D[2])*q+_D[3])*q+1)
    e = normal_cdf(x) - p
    u = e * SQRT2PI * math.exp(x * x / 2)
    return x - u / (1 + x * u / 2)


# ---------------------------------------------------------------- gamma / beta
_LANCZOS = [676.5203681218851, -1259.1392167224028, 771.32342877765313,
            -176.61502916214059, 12.507343278686905, -0.13857109526572012,
            9.9843695780195716e-6, 1.5056327351493116e-7]


def log_gamma(x):
    if x < 0.5:
        return math.log(math.pi / abs(math.sin(math.pi * x))) - log_gamma(1 - x)
    x -= 1
    a = 0.99999999999980993
    t = x + 7.5
    for i, c in enumerate(_LANCZOS):
        a += c / (x + i + 1)
    return 0.5 * math.log(2 * math.pi) + (x + 0.5) * math.log(t) - t + math.log(a)


def _betacf(a, b, x):
    tiny = 1e-300
    qab, qap, qam = a + b, a + 1, a - 1
    c = 1.0
    d = 1 - qab * x / qap
    if abs(d) < tiny:
        d = tiny
    d = 1 / d
    h = d
    for m in range(1, 301):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1 + aa * d
        d = tiny if abs(d) < tiny else d
        c = 1 + aa / c
        c = tiny if abs(c) < tiny else c
        d = 1 / d
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1 + aa * d
        d = tiny if abs(d) < tiny else d
        c = 1 + aa / c
        c = tiny if abs(c) < tiny else c
        d = 1 / d
        de = d * c
        h *= de
        if abs(de - 1) < 1e-15:
            break
    return h


def reg_inc_beta(a, b, x):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    lbt = log_gamma(a + b) - log_gamma(a) - log_gamma(b) + a * math.log(x) + b * math.log(1 - x)
    bt = math.exp(lbt)
    if x < (a + 1) / (a + b + 2):
        return bt * _betacf(a, b, x) / a
    return 1 - bt * _betacf(b, a, 1 - x) / b


# ---------------------------------------------------------------- t de Student
def t_pdf(t, df):
    lc = log_gamma((df + 1) / 2) - log_gamma(df / 2) - 0.5 * math.log(df * math.pi)
    return math.exp(lc - (df + 1) / 2 * math.log(1 + t * t / df))


def t_cdf(t, df):
    x = df / (df + t * t)
    tail = 0.5 * reg_inc_beta(df / 2, 0.5, x)
    return 1 - tail if t > 0 else tail


def t_quantile(p, df):
    if p <= 0 or p >= 1:
        raise ValueError("p fuera de (0,1)")
    lo, hi = -1.0, 1.0
    while t_cdf(lo, df) > p:
        lo *= 2
    while t_cdf(hi, df) < p:
        hi *= 2
    for _ in range(200):
        mid = (lo + hi) / 2
        if t_cdf(mid, df) < p:
            lo = mid
        else:
            hi = mid
        if hi - lo < 1e-12:
            break
    return (lo + hi) / 2


# ---------------------------------------------------------------- binomial
def binom_pmf(k, n, p):
    if k < 0 or k > n:
        return 0.0
    lc = log_gamma(n + 1) - log_gamma(k + 1) - log_gamma(n - k + 1)
    if p == 0:
        return 1.0 if k == 0 else 0.0
    if p == 1:
        return 1.0 if k == n else 0.0
    return math.exp(lc + k * math.log(p) + (n - k) * math.log(1 - p))


def binom_upper(k, n, p):
    """P(X >= k)."""
    return min(1.0, sum(binom_pmf(i, n, p) for i in range(k, n + 1)))


# ---------------------------------------------------------------- inferencia
def z_crit(conf):
    return normal_quantile(1 - (1 - conf) / 2)


def t_crit(conf, df):
    return t_quantile(1 - (1 - conf) / 2, df)


def _p_value(stat, tail, cdf):
    if tail == "two":
        return min(1.0, 2 * min(cdf(stat), 1 - cdf(stat)))
    if tail == "less":
        return cdf(stat)
    if tail == "greater":
        return 1 - cdf(stat)
    raise ValueError(tail)


def _ci(est, se, crit):
    m = crit * se
    return {"estimate": est, "se": se, "critical": crit, "margin": m,
            "lower": est - m, "upper": est + m}


def ci_mean_z(mean, sigma, n, conf):
    return _ci(mean, sigma / math.sqrt(n), z_crit(conf))


def ci_mean_t(mean, sd, n, conf):
    r = _ci(mean, sd / math.sqrt(n), t_crit(conf, n - 1))
    r["df"] = n - 1
    return r


def ci_prop(x, n, conf):
    ph = x / n
    return _ci(ph, math.sqrt(ph * (1 - ph) / n), z_crit(conf))


def welch_df(s1, n1, s2, n2):
    v1, v2 = s1 * s1 / n1, s2 * s2 / n2
    return (v1 + v2) ** 2 / (v1 * v1 / (n1 - 1) + v2 * v2 / (n2 - 1))


def ci_diff_means(m1, s1, n1, m2, s2, n2, conf):
    se = math.sqrt(s1 * s1 / n1 + s2 * s2 / n2)
    df = welch_df(s1, n1, s2, n2)
    r = _ci(m1 - m2, se, t_crit(conf, df))
    r["df"] = df
    return r


def ci_diff_props(x1, n1, x2, n2, conf):
    p1, p2 = x1 / n1, x2 / n2
    se = math.sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
    return _ci(p1 - p2, se, z_crit(conf))


def test_mean_z(mean, sigma, n, mu0, tail):
    se = sigma / math.sqrt(n)
    z = (mean - mu0) / se
    return {"estimate": mean, "se": se, "statistic": z, "p": _p_value(z, tail, normal_cdf)}


def test_mean_t(mean, sd, n, mu0, tail):
    se = sd / math.sqrt(n)
    t = (mean - mu0) / se
    df = n - 1
    return {"estimate": mean, "se": se, "statistic": t, "df": df,
            "p": _p_value(t, tail, lambda v: t_cdf(v, df))}


def test_prop(x, n, p0, tail):
    ph = x / n
    se = math.sqrt(p0 * (1 - p0) / n)
    z = (ph - p0) / se
    return {"estimate": ph, "se": se, "statistic": z, "p": _p_value(z, tail, normal_cdf)}


def test_diff_means(m1, s1, n1, m2, s2, n2, tail):
    se = math.sqrt(s1 * s1 / n1 + s2 * s2 / n2)
    df = welch_df(s1, n1, s2, n2)
    t = (m1 - m2) / se
    return {"estimate": m1 - m2, "se": se, "statistic": t, "df": df,
            "p": _p_value(t, tail, lambda v: t_cdf(v, df))}


def test_diff_props(x1, n1, x2, n2, tail):
    p1, p2 = x1 / n1, x2 / n2
    pp = (x1 + x2) / (n1 + n2)
    se = math.sqrt(pp * (1 - pp) * (1 / n1 + 1 / n2))
    z = (p1 - p2) / se
    return {"estimate": p1 - p2, "se": se, "statistic": z, "pooled": pp,
            "p": _p_value(z, tail, normal_cdf)}


def n_mean(sigma, E, conf):
    return {"n": math.ceil((z_crit(conf) * sigma / E) ** 2 - 1e-9)}


def n_prop(p, E, conf):
    return {"n": math.ceil(z_crit(conf) ** 2 * p * (1 - p) / E ** 2 - 1e-9)}


def se_mean(sd, n):
    return {"se": sd / math.sqrt(n)}


def se_prop(p, n):
    return {"se": math.sqrt(p * (1 - p) / n)}


def cohen_d(m1, s1, n1, m2, s2, n2):
    sp = math.sqrt(((n1 - 1) * s1 * s1 + (n2 - 1) * s2 * s2) / (n1 + n2 - 2))
    return {"d": (m1 - m2) / sp}


def prob_mean_above(mu, sigma, n, a):
    """P(x̄ > a) con x̄ ~ N(mu, sigma/√n)."""
    return {"p": 1 - normal_cdf((a - mu) / (sigma / math.sqrt(n)))}


def prob_mean_between(mu, sigma, n, a, b):
    se = sigma / math.sqrt(n)
    return {"p": normal_cdf((b - mu) / se) - normal_cdf((a - mu) / se)}


def fwer(k, alpha):
    return {"p": 1 - (1 - alpha) ** k}


def power_mean_z(mu0, mu1, sigma, n, alpha, tail):
    se = sigma / math.sqrt(n)
    shift = (mu1 - mu0) / se
    if tail == "greater":
        z = normal_quantile(1 - alpha)
        return {"power": 1 - normal_cdf(z - shift)}
    if tail == "less":
        z = normal_quantile(1 - alpha)
        return {"power": normal_cdf(-z - shift)}
    z = normal_quantile(1 - alpha / 2)
    return {"power": 1 - normal_cdf(z - shift) + normal_cdf(-z - shift)}


FUNCTIONS = {
    "z_crit": lambda a: {"critical": z_crit(a["conf"])},
    "t_crit": lambda a: {"critical": t_crit(a["conf"], a["df"])},
    "ci_mean_z": lambda a: ci_mean_z(a["mean"], a["sigma"], a["n"], a["conf"]),
    "ci_mean_t": lambda a: ci_mean_t(a["mean"], a["sd"], a["n"], a["conf"]),
    "ci_prop": lambda a: ci_prop(a["x"], a["n"], a["conf"]),
    "ci_diff_means": lambda a: ci_diff_means(a["mean1"], a["sd1"], a["n1"], a["mean2"], a["sd2"], a["n2"], a["conf"]),
    "ci_diff_props": lambda a: ci_diff_props(a["x1"], a["n1"], a["x2"], a["n2"], a["conf"]),
    "test_mean_z": lambda a: test_mean_z(a["mean"], a["sigma"], a["n"], a["mu0"], a["tail"]),
    "test_mean_t": lambda a: test_mean_t(a["mean"], a["sd"], a["n"], a["mu0"], a["tail"]),
    "test_prop": lambda a: test_prop(a["x"], a["n"], a["p0"], a["tail"]),
    "test_diff_means": lambda a: test_diff_means(a["mean1"], a["sd1"], a["n1"], a["mean2"], a["sd2"], a["n2"], a["tail"]),
    "test_diff_props": lambda a: test_diff_props(a["x1"], a["n1"], a["x2"], a["n2"], a["tail"]),
    "n_mean": lambda a: n_mean(a["sigma"], a["E"], a["conf"]),
    "n_prop": lambda a: n_prop(a["p"], a["E"], a["conf"]),
    "se_mean": lambda a: se_mean(a["sd"], a["n"]),
    "se_prop": lambda a: se_prop(a["p"], a["n"]),
    "binom_upper": lambda a: {"p": binom_upper(a["k"], a["n"], a["p"])},
    "cohen_d": lambda a: cohen_d(a["mean1"], a["sd1"], a["n1"], a["mean2"], a["sd2"], a["n2"]),
    "prob_mean_above": lambda a: prob_mean_above(a["mu"], a["sigma"], a["n"], a["a"]),
    "prob_mean_between": lambda a: prob_mean_between(a["mu"], a["sigma"], a["n"], a["a"], a["b"]),
    "fwer": lambda a: fwer(a["k"], a["alpha"]),
    "power_mean_z": lambda a: power_mean_z(a["mu0"], a["mu1"], a["sigma"], a["n"], a["alpha"], a["tail"]),
}


def evaluate(fn, args):
    if fn not in FUNCTIONS:
        raise KeyError("función desconocida: " + fn)
    return FUNCTIONS[fn](args)
