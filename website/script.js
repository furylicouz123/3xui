// Файловая система и текущая директория
let currentDirectory = '/home/root';
let fileSystem = {
    '/': {
        'home': {
            'root': {
                'documents': {
                    'secret.txt': 'TOP SECRET: Access codes - 1337h4x0r',
                    'passwords.txt': 'admin:password123\nroot:toor\nhacker:anonymous'
                },
                'downloads': {},
                'desktop': {
                    'hack_tools.sh': '#!/bin/bash\necho "Launching hacking tools..."\necho "[+] Nmap scanning..."\necho "[+] Metasploit loading..."'
                },
                '.bashrc': 'export PS1="\\u@\\h:\\w# "\nalias ll="ls -la"\nalias hack="echo HACKING IN PROGRESS..."'
            }
        },
        'etc': {
            'passwd': 'root:x:0:0:root:/root:/bin/bash\nhacker:x:1000:1000::/home/hacker:/bin/bash',
            'shadow': 'root:$6$salt$encrypted_password_hash::0:99999:7:::'
        },
        'var': {
            'log': {
                'auth.log': '[2024-01-15 12:34:56] Failed login attempt from 192.168.1.100\n[2024-01-15 12:35:01] Successful login: root'
            }
        },
        'tmp': {}
    }
};

// История команд
let commandHistory = [];
let historyIndex = -1;

// Получение текущей директории из файловой системы
function getCurrentDir() {
    if (currentDirectory === '/') {
        return fileSystem['/'];
    }
    
    const parts = currentDirectory.split('/').filter(p => p);
    let current = fileSystem['/'];
    
    for (const part of parts) {
        if (current && current[part] && typeof current[part] === 'object') {
            current = current[part];
        } else {
            return null;
        }
    }
    return current;
}

// Команды терминала
const commands = {
    help: () => {
        return `Доступные команды:
  ls          - список файлов и папок
  cd <dir>    - перейти в директорию
  cat <file>  - показать содержимое файла
  pwd         - показать текущую директорию
  whoami      - показать текущего пользователя
  uname       - информация о системе
  ps          - список процессов
  netstat     - сетевые соединения
  ping <host> - проверить соединение с хостом
  vulnscan <site> - найти уязвимости сайта
  mkdir <dir> - создать директорию
  touch <file>- создать файл
  rm <file>   - удалить файл
  passwd      - изменить пароль
  sudo        - выполнить с правами root
  nano <file> - редактировать файл
  grep        - поиск в файлах
  find        - найти файлы
  hack        - запустить хакерские инструменты

  clear       - очистить терминал
  exit        - выход
  help        - показать эту справку`;
    },
    
    ls: (args) => {
        const currentDir = getCurrentDir();
        if (!currentDir) return 'ls: cannot access directory';
        
        const items = Object.keys(currentDir);
        if (args && args[0] === '-la') {
            let result = 'total ' + items.length + '\n';
            result += 'drwxr-xr-x 2 root root 4096 Jan 15 12:34 .\n';
            result += 'drwxr-xr-x 3 root root 4096 Jan 15 12:33 ..\n';
            
            items.forEach(item => {
                const isDir = typeof currentDir[item] === 'object' && !currentDir[item].includes;
                const permissions = isDir ? 'drwxr-xr-x' : '-rw-r--r--';
                const size = isDir ? '4096' : '1024';
                result += `${permissions} 1 root root ${size} Jan 15 12:34 ${item}\n`;
            });
            return result;
        }
        
        return items.length > 0 ? items.join('  ') : '';
    },
    
    cd: (args) => {
        if (!args || args.length === 0) {
            currentDirectory = '/home/root';
            return '';
        }
        
        const target = args[0];
        let newPath;
        
        if (target.startsWith('/')) {
            newPath = target;
        } else if (target === '..') {
            const parts = currentDirectory.split('/').filter(p => p);
            parts.pop();
            newPath = '/' + parts.join('/');
            if (newPath === '/') newPath = '/';
        } else {
            newPath = currentDirectory === '/' ? '/' + target : currentDirectory + '/' + target;
        }
        
        // Проверяем существование директории
        const parts = newPath.split('/').filter(p => p);
        let current = fileSystem['/'];
        
        for (const part of parts) {
            if (current && current[part] && typeof current[part] === 'object') {
                current = current[part];
            } else {
                return `cd: ${target}: No such file or directory`;
            }
        }
        
        currentDirectory = newPath || '/';
        return '';
    },
    
    cat: (args) => {
        if (!args || args.length === 0) {
            return 'cat: missing file operand';
        }
        
        const filename = args[0];
        const currentDir = getCurrentDir();
        
        if (currentDir && currentDir[filename] && typeof currentDir[filename] === 'string') {
            return currentDir[filename];
        }
        
        return `cat: ${filename}: No such file or directory`;
    },
    
    pwd: () => currentDirectory,
    
    whoami: () => 'root',
    
    uname: (args) => {
        if (args && args[0] === '-a') {
            return 'Linux hackermachine 5.15.0-kali3-amd64 #1 SMP Debian 5.15.15-2kali1 (2022-01-31) x86_64 GNU/Linux';
        }
        return 'Linux';
    },
    
    ps: () => {
        return `  PID TTY          TIME CMD
 1337 pts/0    00:00:01 bash
 1338 pts/0    00:00:00 hack_tool
 1339 pts/0    00:00:00 nmap
 1340 pts/0    00:00:00 metasploit
 1341 pts/0    00:00:00 ps`;
    },
    
    netstat: () => {
        return `Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 192.168.1.100:22        192.168.1.1:54321       ESTABLISHED
tcp        0      0 192.168.1.100:80        0.0.0.0:*               LISTEN
tcp        0      0 192.168.1.100:443       0.0.0.0:*               LISTEN`;
    },

    ping: (args) => {
        if (!args || args.length === 0) {
            return 'ping: usage: ping <hostname>';
        }
        
        const host = args[0];
        const responses = [
            `PING ${host} (${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}): 56 data bytes`,
            `64 bytes from ${host}: icmp_seq=1 ttl=64 time=${(Math.random() * 50 + 10).toFixed(1)}ms`,
            `64 bytes from ${host}: icmp_seq=2 ttl=64 time=${(Math.random() * 50 + 10).toFixed(1)}ms`,
            `64 bytes from ${host}: icmp_seq=3 ttl=64 time=${(Math.random() * 50 + 10).toFixed(1)}ms`,
            `64 bytes from ${host}: icmp_seq=4 ttl=64 time=${(Math.random() * 50 + 10).toFixed(1)}ms`,
            `\n--- ${host} ping statistics ---`,
            `4 packets transmitted, 4 received, 0% packet loss`,
            `round-trip min/avg/max/stddev = ${(Math.random() * 20 + 5).toFixed(1)}/${(Math.random() * 30 + 20).toFixed(1)}/${(Math.random() * 40 + 35).toFixed(1)}/${(Math.random() * 5 + 2).toFixed(1)} ms`
        ];
        
        return responses.join('\n');
    },

    vulnscan: (args) => {
        if (!args || args.length === 0) {
            return 'vulnscan: usage: vulnscan <website>';
        }
        
        const website = args[0];
        const vulnerabilities = [
            'SQL Injection',
            'Cross-Site Scripting (XSS)',
            'Cross-Site Request Forgery (CSRF)',
            'Directory Traversal',
            'Remote Code Execution',
            'Authentication Bypass',
            'Session Hijacking',
            'Buffer Overflow',
            'Privilege Escalation',
            'Information Disclosure',
            'Weak SSL/TLS Configuration',
            'Insecure Direct Object References',
            'Security Misconfiguration',
            'Sensitive Data Exposure'
        ];
        
        const randomVulns = vulnerabilities.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 6) + 3);
        const randomIP = `${Math.floor(Math.random() * 256)}.${Math.floor(Math.random() * 256)}.${Math.floor(Math.random() * 256)}.${Math.floor(Math.random() * 256)}`;
        
        const responses = [
            `[+] Starting vulnerability scan for ${website}`,
            `[+] Target resolved to IP: ${randomIP}`,
            `[+] Initializing Nmap security scanner v7.94...`,
            `[+] Loading CVE database (2024.01.15)...`,
            `[+] Loading exploit database (47,892 exploits)...`,
            `[+] Starting TCP SYN scan...`,
            `[+] Scanning 1000 most common ports...`,
            `[+] Port 21/tcp: CLOSED - FTP`,
            `[+] Port 22/tcp: FILTERED - SSH`,
            `[+] Port 23/tcp: CLOSED - Telnet`,
            `[+] Port 25/tcp: CLOSED - SMTP`,
            `[+] Port 53/tcp: CLOSED - DNS`,
            `[+] Port 80/tcp: OPEN - HTTP (Apache/2.4.41)`,
            `[+] Port 110/tcp: CLOSED - POP3`,
            `[+] Port 143/tcp: CLOSED - IMAP`,
            `[+] Port 443/tcp: OPEN - HTTPS (Apache/2.4.41 OpenSSL/1.1.1)`,
            `[+] Port 993/tcp: CLOSED - IMAPS`,
            `[+] Port 995/tcp: CLOSED - POP3S`,
            `[+] Port 3000/tcp: FILTERED - Node.js`,
            `[+] Port 3306/tcp: CLOSED - MySQL`,
            `[+] Port 5432/tcp: CLOSED - PostgreSQL`,
            `[+] Port 8080/tcp: FILTERED - HTTP-Proxy`,
            `[+] Port scan completed. 2 open, 3 filtered, 995 closed`,
            `[+] Starting service detection...`,
            `[+] HTTP/80: Server Apache/2.4.41 (Ubuntu)`,
            `[+] HTTPS/443: Server Apache/2.4.41 OpenSSL/1.1.1f`,
            `[+] SSL Certificate: CN=${website}, Valid until 2025-03-15`,
            `[+] Starting web application security tests...`,
            `[+] Testing for common web vulnerabilities...`,
            `[+] Checking robots.txt... Found`,
            `[+] Checking sitemap.xml... Not found`,
            `[+] Directory enumeration: /admin, /login, /api, /uploads`,
            `[+] Testing SQL injection on 15 parameters...`,
            `[+] Testing XSS on 23 input fields...`,
            `[+] Testing CSRF protection...`,
            `[+] Analyzing HTTP security headers...`,
            `[+] X-Frame-Options: MISSING`,
            `[+] X-XSS-Protection: MISSING`,
            `[+] X-Content-Type-Options: MISSING`,
            `[+] Content-Security-Policy: MISSING`,
            `[+] Strict-Transport-Security: MISSING`,
            `[+] Testing SSL/TLS configuration...`,
            `[+] SSL Labs Grade: B (Weak cipher suites detected)`,
            `[+] Running Nikto web scanner...`,
            `[+] Testing for known vulnerabilities...`,
            `[!] CRITICAL VULNERABILITIES DETECTED:`,
            ...randomVulns.map((vuln, index) => {
                const severity = ['CRITICAL', 'HIGH', 'MEDIUM'][Math.floor(Math.random() * 3)];
                const cvss = (Math.random() * 4 + 6).toFixed(1);
                return `    [${index + 1}] ${vuln} - ${severity} (CVSS: ${cvss})`;
            }),
            `[+] Vulnerability assessment completed`,
            `[+] Total vulnerabilities found: ${randomVulns.length}`,
            `[+] Risk level: ${randomVulns.length > 4 ? 'CRITICAL' : randomVulns.length > 2 ? 'HIGH' : 'MEDIUM'}`,
            `[+] Generating detailed report...`,
            `[+] Updating exploit database...`,
            `[+] Cross-referencing with Metasploit modules...`,
            `[+] Generating attack vectors and payloads...`,
            `[+] Report saved to /tmp/vulnscan_${website.replace(/\./g, '_')}_${Date.now()}.txt`,
            `[+] JSON report saved to /tmp/vulnscan_${website.replace(/\./g, '_')}_${Date.now()}.json`,
            `[!] ========================================`,
            `[!] SCAN COMPLETED - ${new Date().toLocaleString()}`,
            `[!] Target: ${website} (${randomIP})`,
            `[!] Duration: ${Math.floor(Math.random() * 300 + 120)} seconds`,
            `[!] ========================================`,
            `[!] WARNING: This tool is for authorized testing only!`,
            `[!] Unauthorized scanning may violate laws and regulations!`
        ];
        
        // Используем постепенный вывод с задержками для хакерского эффекта
        addToTerminalWithDelay(responses, 'output', 400);
        return ''; // Возвращаем пустую строку, так как вывод происходит асинхронно
    },
    
    hack: () => {
        return `[+] Initializing hacking tools...
[+] Loading exploits database...
[+] Scanning for vulnerabilities...
[+] Found 15 potential targets
[+] Launching attack vectors...
[!] WARNING: Unauthorized access detected
[+] Bypassing security measures...
[+] Access granted to mainframe
[+] HACK SUCCESSFUL! 🔓`;
    },
    

    
    clear: () => {
        document.getElementById('terminal-output').innerHTML = '';
        return '';
    },
    
    exit: () => {
        return 'Connection terminated by foreign host.';
    },
    
    mkdir: (args) => {
        if (!args || args.length === 0) {
            return 'mkdir: missing operand';
        }
        
        const dirName = args[0];
        const currentDir = getCurrentDir();
        
        if (!currentDir) {
            return 'mkdir: cannot create directory';
        }
        
        if (currentDir[dirName]) {
            return `mkdir: cannot create directory '${dirName}': File exists`;
        }
        
        currentDir[dirName] = {};
        return '';
    },
    
    touch: (args) => {
        if (!args || args.length === 0) {
            return 'touch: missing file operand';
        }
        
        const fileName = args[0];
        const currentDir = getCurrentDir();
        
        if (!currentDir) {
            return 'touch: cannot create file';
        }
        
        currentDir[fileName] = '';
        return '';
    },
    
    rm: (args) => {
        if (!args || args.length === 0) {
            return 'rm: missing operand';
        }
        
        const fileName = args[0];
        const currentDir = getCurrentDir();
        
        if (!currentDir || !currentDir[fileName]) {
            return `rm: cannot remove '${fileName}': No such file or directory`;
        }
        
        delete currentDir[fileName];
        return '';
    },
    
    passwd: () => {
        return `Changing password for root.
Current password: 
New password: 
Retype new password: 
passwd: password updated successfully`;
    },
    
    sudo: (args) => {
        if (!args || args.length === 0) {
            return 'sudo: a command is required';
        }
        
        const command = args.join(' ');
        return `[sudo] password for root: \nExecuting: ${command}\n` + executeCommand(command);
    },
    
    nano: (args) => {
        if (!args || args.length === 0) {
            return 'nano: missing filename';
        }
        
        const fileName = args[0];
        return `GNU nano 6.2    ${fileName}\n\n[ File: ${fileName} ]\n[ Use Ctrl+X to exit ]\n\nFile opened in nano editor (simulated)`;
    },
    
    grep: (args) => {
        if (!args || args.length < 2) {
            return 'grep: missing pattern or file';
        }
        
        const pattern = args[0];
        const fileName = args[1];
        const currentDir = getCurrentDir();
        
        if (!currentDir || !currentDir[fileName]) {
            return `grep: ${fileName}: No such file or directory`;
        }
        
        const content = currentDir[fileName];
        if (typeof content !== 'string') {
            return `grep: ${fileName}: Is a directory`;
        }
        
        const lines = content.split('\n');
        const matches = lines.filter(line => line.includes(pattern));
        
        return matches.length > 0 ? matches.join('\n') : '';
    },
    
    find: (args) => {
        const searchPath = args && args.length > 0 ? args[0] : '.';
        const currentDir = getCurrentDir();
        
        if (!currentDir) {
            return 'find: cannot access directory';
        }
        
        function findFiles(dir, path = '') {
            let results = [];
            for (const [name, content] of Object.entries(dir)) {
                const fullPath = path ? `${path}/${name}` : name;
                results.push(fullPath);
                if (typeof content === 'object' && content !== null) {
                    results = results.concat(findFiles(content, fullPath));
                }
            }
            return results;
        }
        
        const files = findFiles(currentDir);
        return files.join('\n');
    }
};

// Обработка команд
function executeCommand(input) {
    const parts = input.trim().split(' ');
    const command = parts[0].toLowerCase();
    const args = parts.slice(1);
    
    if (commands[command]) {
        return commands[command](args);
    } else if (input.trim() === '') {
        return '';
    } else {
        return `bash: ${command}: command not found`;
    }
}

// Добавление строки в терминал
function addToTerminal(content, className = 'output') {
    const output = document.getElementById('terminal-output');
    const line = document.createElement('div');
    line.className = 'terminal-line';
    
    const span = document.createElement('span');
    span.className = className;
    span.textContent = content;
    line.appendChild(span);
    
    output.appendChild(line);
    
    // Мгновенная прокрутка вниз как в Linux системах
    output.scrollTop = output.scrollHeight;
}

// Функция для постепенного вывода строк с задержками (хакерский эффект)
function addToTerminalWithDelay(lines, className = 'output', delay = 800) {
    lines.forEach((line, index) => {
        setTimeout(() => {
            addToTerminal(line, className);
        }, index * delay);
    });
}

// Обработка ввода
// Обновление промпта
function updatePrompt() {
    const promptElement = document.querySelector('.prompt');
    promptElement.textContent = `root@hackermachine:${currentDirectory}# `;
}

function handleInput() {
    const input = document.getElementById('terminal-input');
    const command = input.value;
    
    if (command.trim() !== '') {
        // Добавляем команду в историю
        commandHistory.push(command);
        historyIndex = commandHistory.length;
        
        // Показываем команду
        addToTerminal(`root@hackermachine:${currentDirectory}# ${command}`, 'command');
        
        // Выполняем команду
        const result = executeCommand(command);
        if (result) {
            result.split('\n').forEach(line => {
                addToTerminal(line, result.includes('error') || result.includes('not found') ? 'error' : 'output');
            });
        }
        
        // Обновляем промпт после выполнения команды
        updatePrompt();
    }
    
    input.value = '';
}



// Музыка
let musicPlaying = false;
let audioContext;
let musicInterval;

// Функция toggleMusic удалена, так как музыка теперь всегда включена

function startHackerMusic() {
    try {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        
        // Хакерская мелодия с более агрессивным звуком
        const frequencies = [130.81, 146.83, 164.81, 174.61, 196, 220, 246.94, 261.63];
        let currentNote = 0;
        let beatCount = 0;
        
        function playBeat() {
            if (!musicPlaying) return;
            
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            const filterNode = audioContext.createBiquadFilter();
            
            oscillator.connect(filterNode);
            filterNode.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            // Настройка звука
            oscillator.frequency.setValueAtTime(frequencies[currentNote], audioContext.currentTime);
            oscillator.type = beatCount % 4 === 0 ? 'sawtooth' : 'square';
            
            filterNode.type = 'lowpass';
            filterNode.frequency.setValueAtTime(800 + Math.sin(beatCount * 0.1) * 400, audioContext.currentTime);
            
            gainNode.gain.setValueAtTime(0, audioContext.currentTime);
            gainNode.gain.linearRampToValueAtTime(0.15, audioContext.currentTime + 0.01);
            gainNode.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.3);
            
            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.3);
            
            currentNote = (currentNote + (beatCount % 2 === 0 ? 1 : 2)) % frequencies.length;
            beatCount++;
        }
        
        // Запускаем ритм
        musicInterval = setInterval(playBeat, 400);
        playBeat(); // Первый удар сразу
        
    } catch (error) {
        console.log('Audio context error:', error);
        // Fallback - показываем визуальный индикатор
        document.querySelector('.audio-button').style.animation = 'pulse 0.5s infinite';
    }
}

function stopHackerMusic() {
    musicPlaying = false;
    if (musicInterval) {
        clearInterval(musicInterval);
        musicInterval = null;
    }
    if (audioContext && audioContext.state !== 'closed') {
        audioContext.close();
        audioContext = null;
    }
    document.querySelector('.audio-button').style.animation = 'none';
}

// Инициализация
document.addEventListener('DOMContentLoaded', function() {
    const input = document.getElementById('terminal-input');
    let musicStarted = false;
    
    // Функция для запуска музыки
    function startMusicOnInteraction() {
        if (!musicStarted) {
            startHackerMusic();
            musicPlaying = true;
            musicStarted = true;
        }
    }
    
    // Попытка автоматического запуска музыки
    function tryAutoStartMusic() {
        try {
            // Создаем тихий звук для активации AudioContext
            const tempContext = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = tempContext.createOscillator();
            const gainNode = tempContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(tempContext.destination);
            
            gainNode.gain.setValueAtTime(0.001, tempContext.currentTime);
            oscillator.frequency.setValueAtTime(20, tempContext.currentTime);
            oscillator.start(tempContext.currentTime);
            oscillator.stop(tempContext.currentTime + 0.01);
            
            // Если успешно, запускаем основную музыку
            setTimeout(() => {
                tempContext.close();
                startMusicOnInteraction();
            }, 100);
            
        } catch (error) {
            // Если не получилось, ждем взаимодействия пользователя
            console.log('Autoplay blocked, waiting for user interaction');
        }
    }
    
    // Фокус на поле ввода
    input.focus();
    
    // Обработка Enter
    input.addEventListener('keydown', function(e) {
        startMusicOnInteraction();
        
        if (e.key === 'Enter') {
            handleInput();
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (historyIndex > 0) {
                historyIndex--;
                input.value = commandHistory[historyIndex];
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (historyIndex < commandHistory.length - 1) {
                historyIndex++;
                input.value = commandHistory[historyIndex];
            } else {
                historyIndex = commandHistory.length;
                input.value = '';
            }
        }
    });
    
    // Клик по терминалу возвращает фокус на ввод и запускает музыку
    document.querySelector('.terminal').addEventListener('click', function() {
        startMusicOnInteraction();
        input.focus();
    });
    
    // Обработчик прокрутки колесика мыши для Linux-подобного поведения
    document.querySelector('.terminal').addEventListener('wheel', function(e) {
        e.preventDefault(); // Полностью контролируем прокрутку
        
        const terminal = this;
        const scrollAmount = 40; // Размер одного шага прокрутки
        const maxScrollTop = Math.max(0, terminal.scrollHeight - terminal.clientHeight);
        
        if (e.deltaY > 0) {
            // Прокрутка вниз - ограничиваем максимальной позицией
            terminal.scrollTop = Math.min(terminal.scrollTop + scrollAmount, maxScrollTop);
        } else {
            // Прокрутка вверх - ограничиваем нулем
            terminal.scrollTop = Math.max(terminal.scrollTop - scrollAmount, 0);
        }
    });
    
    // Обработчик клика на body для автоматического запуска
    document.body.addEventListener('click', function() {
        startMusicOnInteraction();
    });
    
    // Попытка запуска музыки при движении мыши
    document.addEventListener('mousemove', function() {
        startMusicOnInteraction();
    }, { once: true });
    
    // Попытка запуска музыки при скролле
    document.addEventListener('scroll', function() {
        startMusicOnInteraction();
    }, { once: true });
    
    // Обновляем промпт при загрузке
    updatePrompt();
    
    // Попытка автоматического запуска через небольшую задержку
    setTimeout(tryAutoStartMusic, 500);
    
    // Программный клик для обхода ограничений браузера
    setTimeout(() => {
        if (!musicStarted) {
            // Создаем и диспетчеризируем событие клика
            const clickEvent = new MouseEvent('click', {
                view: window,
                bubbles: true,
                cancelable: true
            });
            document.body.dispatchEvent(clickEvent);
            
            // Также пробуем через focus и blur
            input.focus();
            input.blur();
            input.focus();
            
            // Принудительный запуск музыки
            setTimeout(() => {
                if (!musicStarted) {
                    startMusicOnInteraction();
                }
            }, 100);
        }
    }, 1000);

});