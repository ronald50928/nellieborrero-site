function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // If URI ends with '/', append 'index.html'
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    // If URI doesn't have an extension and doesn't end with '/', append '/index.html'
    else if (!uri.includes('.') && !uri.endsWith('/')) {
        request.uri += '/index.html';
    }
    
    return request;
}
