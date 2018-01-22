let active = false;
let log = console.log;
let keys;
window.addEventListener('keypress', (e) => {
    log('pressed:', e.key, e.code);
    if (!active && e.altKey && e.code == 'BracketLeft') {
        log('Start the record!');
        active = true;
        keys = [];
    } else if (active && e.altKey && e.code == 'BracketLeft') {
        log('Stop the record!');
        active = false;
        log('Your data is:');
        let out = '[';
        for (let i = 0; i < keys.length; i++) {
            out += `'${keys[i]}'`;
            if (i != keys.length - 1) {
                out += ', ';
            }
        }
        out += ']';
        console.log(out);
    } else if (active) {
        keys.push(e.code);
    }
});