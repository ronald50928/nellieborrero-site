function handler(event) {
    var response = event.response;
    var headers = response.headers;

    // Security Headers
    headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubdomains; preload' };
    headers['content-security-policy'] = { 
        value: "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://www.google-analytics.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://www.google-analytics.com; frame-ancestors 'none';" 
    };
    headers['x-content-type-options'] = { value: 'nosniff' };
    headers['x-frame-options'] = { value: 'DENY' };
    headers['x-xss-protection'] = { value: '1; mode=block' };
    headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
    headers['permissions-policy'] = { 
        value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()' 
    };

    // Performance Headers
    headers['cache-control'] = { value: 'public, max-age=300' };

    return response;
}
