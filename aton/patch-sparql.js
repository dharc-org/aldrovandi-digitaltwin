#!/usr/bin/env node
/**
 * Script per aggiornare l'endpoint SPARQL nei file del progetto Aldrovandi
 */

const fs = require('fs');
const path = require('path');

const newEndpoint = process.argv[2];
if (!newEndpoint) {
    console.log('Uso: node patch-sparql.js <nuovo_endpoint>');
    process.exit(0);
}

const aldrovandi_dir = '/app/aton/wapps/aldrovandi';

// Pattern comuni per endpoint SPARQL
const patterns = [
    /http:\/\/localhost:3030\/chad-kg\/sparql/g,
    /http:\/\/host\.docker\.internal:3030\/chad-kg\/sparql/g,
    /http:\/\/127\.0\.0\.1:3030\/chad-kg\/sparql/g
];

function patchFile(filePath) {
    try {
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;
        
        patterns.forEach(pattern => {
            if (pattern.test(content)) {
                content = content.replace(pattern, newEndpoint);
                modified = true;
            }
        });
        
        if (modified) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Patchato: ${filePath}`);
        }
    } catch (err) {
        // Ignora errori di lettura
    }
}

function walkDir(dir, extensions) {
    if (!fs.existsSync(dir)) return;
    
    const files = fs.readdirSync(dir);
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
            walkDir(filePath, extensions);
        } else if (stat.isFile()) {
            const ext = path.extname(file).toLowerCase();
            if (extensions.includes(ext)) {
                patchFile(filePath);
            }
        }
    });
}

console.log(`Patching endpoint SPARQL a: ${newEndpoint}`);
walkDir(aldrovandi_dir, ['.js', '.json', '.html', '.py', '.config']);
console.log('Patch completato.');
