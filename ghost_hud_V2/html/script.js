let rotationInterval;
let currentConfig = {};

// Atualiza o relógio
function updateClock() {
    fetch(`https://${GetParentResourceName()}/getGameTime`)
        .then(response => response.json())
        .then(data => {
            const hours = data.hours.toString().padStart(2, '0');
            const minutes = data.minutes.toString().padStart(2, '0');
            document.getElementById('time').textContent = `${hours}:${minutes}`;
            
            // Adiciona classe para noite/dia baseado na hora
            const clock = document.getElementById('clock');
            clock.classList.toggle('night-time', data.hours < 6 || data.hours >= 18);
        })
        .catch(error => console.error('Error fetching game time:', error));
}

setInterval(updateClock, 1000);
updateClock();

// Atualiza a barra de vida
function setHealthBar(percent) {
    const healthBar = document.getElementById('health-bar-progress');
    const healthValue = document.getElementById('health-value');
    
    if (healthBar) {
        healthBar.style.width = `${percent}%`;
        
        // Mudar cor conforme a vida diminui
        if (percent <= 20) {
            healthBar.style.background = '#ff3e3e';
        } else if (percent <= 50) {
            healthBar.style.background = '#ffaa3e';
        } else {
            healthBar.style.background = 'linear-gradient(90deg, #ffffff, #f0f0f0)';
        }
    }
    
    if (healthValue) {
        healthValue.textContent = Math.round(percent);
        
        if (percent <= 50) {
            healthValue.style.color = 'white';
            healthValue.style.textShadow = '0 0 5px rgba(255, 0, 0, 0.8)';
        } else {
            healthValue.style.color = '#333';
            healthValue.style.textShadow = '0 1px 2px rgba(255, 255, 255, 0.5)';
        }
    }
}

// Atualiza os valores de status
function updateStatusValue(elementId, value) {
    const el = document.getElementById(elementId);
    if (el) el.textContent = Math.round(value);
}

function updateStatusFill(elementId, percent) {
    const icon = document.getElementById(elementId)?.querySelector('i');
    if (icon) {
        icon.style.setProperty('--fill-percent', `${percent}%`);
        
        // Atualiza a cor de fundo do pseudo-elemento
        if (percent > 0) {
            icon.classList.add('filled');
        } else {
            icon.classList.remove('filled');
        }
    }
}


// Ouvinte de mensagens NUI
window.addEventListener('message', (event) => {
    const data = event.data;
    const logo = document.getElementById('logo');

    if (data.action === "updateStatus") {
        setHealthBar(data.health);
        updateStatusFill('armor', data.armor);
        updateStatusFill('hunger', data.hunger);
        updateStatusFill('thirst', data.thirst);
        updateStatusFill('stamina', data.stamina);
        updateStatusFill('stress', data.stress);
        updateStatusFill('radiation', data.radiation);
        updateStatusFill('temperature', data.temperature);
        updateStatusFill('voice', data.voicePercent);
        
        // Atualiza os valores de texto
        updateStatusValue('armor-value', data.armor);
        updateStatusValue('hunger-value', data.hunger);
        updateStatusValue('thirst-value', data.thirst);
        updateStatusValue('stamina-value', data.stamina);
        updateStatusValue('stress-value', data.stress);
        updateStatusValue('radiation-value', data.radiation);
        updateStatusValue('temperature-value', data.temperature);
        updateStatusValue('voice-value', data.voicePercent);

    
        // Atualiza temperatura se existir
        const temperatureEl = document.getElementById("temperature-value");
        if (temperatureEl && data.temperature !== undefined) {
            temperatureEl.textContent = `${Math.round(data.temperature)}°C`;
        }

        // Atualiza o logo se existir
        if (logo) {
            logo.style.display = data.logoEnabled ? 'block' : 'none';
            logo.src = data.logoUrl || 'https://i.ibb.co/r6tHLcL/logo.png'; // URL padrão se não fornecido
        } else {
            console.warn("Logo element not found. Ensure it exists in your HTML.");
        }

    const voiceEl = document.getElementById("voice");
    if (voiceEl) {
        updateStatusFill('voice', data.voicePercent);
        voiceEl.classList.toggle('talking', data.isTalking);
        const voiceValueEl = document.getElementById("voice-value");
        if (voiceValueEl) {
            voiceValueEl.textContent = `${Math.round(data.voicePercent)}%`;
        }
        if (data.voiceMode) {
            voiceEl.className = 'status-item'; // Reseta as classes
            voiceEl.classList.add(data.voiceMode.toLowerCase()); // whisper, normal, shout
        }
    }

    }
if (data.action === "updateVoice") {
    const voiceEl = document.getElementById("voice");
    if (voiceEl) {
        voiceEl.classList.remove('whisper', 'normal', 'shout', 'talking');

        if (data.voiceMode) {
            voiceEl.classList.add(data.voiceMode);
        }

        updateStatusFill('voice', data.voicePercent);

        if (data.isTalking) {
            voiceEl.classList.add('talking');
        }
        
        const voiceModeEl = document.getElementById("voice-mode");
        if (voiceModeEl) {
            const modeText = {
                'whisper': 'Sussurro',
                'normal': 'Normal',
                'shout': 'Gritando'
            };
            voiceModeEl.textContent = modeText[data.voiceMode] || 'Normal';
        }
    }
}

    if (data.temperature !== undefined) {
        const tempEl = document.getElementById("temperature-value");
        if (tempEl) {
            const roundedTemp = Math.round(data.temperature * 10) / 10;
            tempEl.textContent = `${roundedTemp}°C`;
            
            // Atualiza a cor baseada na temperatura
            tempEl.className = 'status-value';
            if (data.temperature < 5) {
                tempEl.classList.add('temp-cold');
            } else if (data.temperature > 35) {
                tempEl.classList.add('temp-hot');
            }
            
            // Atualiza o preenchimento do ícone (0-100%)
            const tempPercent = Math.min(100, Math.max(0, (data.temperature + 10) * 2.5));
            updateStatusFill('temperature', tempPercent);
        }
    }
    
if (data.action === "updateRadio") {
    const radioEl = document.getElementById("radio-hud");
    const frequencyEl = document.getElementById("radio-frequency");
    
    if (radioEl && frequencyEl) {
        frequencyEl.textContent = data.frequency || "OFF";
        if (data.show) {
            radioEl.classList.remove('hidden');
        } else {
            radioEl.classList.add('hidden');
        }
    }
}

    if (data.action === "updateHUD") {
        currentConfig = data.config; 
        UpdateHUDPosition(data.config);
    }

    if (data.action === "vehicleHUD") {
        const el = document.getElementById("vehicle-hud");
        if (data.show) {
            el.classList.remove("hidden");
            document.getElementById("speed").textContent = data.speed;
            document.getElementById("fuel").textContent = Math.round(data.fuel);
            
            // Atualiza RPM
            if (data.rpm !== undefined) {
                const rpmPercent = Math.min(100, data.rpm * 100);
                document.getElementById("rpm-bar").style.width = `${rpmPercent}%`;
                document.querySelector(".rpm-value").textContent = `${Math.round(data.rpm * 7000)} RPM`;
            }
            
            // Atualiza marcha
            if (data.gear !== undefined) {
                const gearEl = document.getElementById("gear-indicator");
                gearEl.textContent = data.gear === -1 ? 'R' : (data.gear === 0 ? 'N' : data.gear);
            }

            const engineEl = document.getElementById("engine-status");
            engineEl.classList.toggle('on', data.engine);
            engineEl.classList.toggle('off', !data.engine);
            
            const lockEl = document.getElementById("lock-status");
            lockEl.classList.toggle('locked', data.locked);
            lockEl.classList.toggle('unlocked', !data.locked);
            
            const seatbeltEl = document.getElementById("seatbelt-status");
            seatbeltEl.classList.toggle('on', data.seatbelt);
            seatbeltEl.classList.toggle('off', !data.seatbelt);

            if (data.engine) {
                engineEl.classList.add('active');
            } else {
                engineEl.classList.remove('active');
            }
        } else {
            el.classList.add("hidden");
        }
    }

    if (data.action === "updateStreet") {
        const streetElement = document.getElementById('street-name');
        if (streetElement) {
            streetElement.textContent = data.streetName;
        }
    }

    if (data.action === "updateWeapon") {
        const el = document.getElementById("weapon-hud");
        el.classList.remove("hidden");
        document.getElementById("ammo-clip").textContent = data.ammoClip;
        document.getElementById("ammo-inventory").textContent = data.ammoInventory;
    }
    
    if (data.action === "hideWeapon") {
        document.getElementById("weapon-hud").classList.add("hidden");
    }

    if (data.action === "updatePlayerData") {
        // Dinheiro
        if (data.money !== undefined) {
            document.getElementById("money-value").textContent = formatMoney(data.money);
        }
        
        // Emprego
        if (data.job !== undefined) {
            const jobText = data.job + (data.jobGrade ? ` (${data.jobGrade})` : '');
            document.getElementById("job-name").textContent = jobText;
        }
        
        // ID (Server ID + Citizen ID completo)
        if (data.serverId !== undefined && data.citizenId !== undefined) {
            document.getElementById("id-card-name").textContent = `#${data.serverId} | ${data.citizenId}`;
        }
    }
});

window.addEventListener('load', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ message: 'NUI is ready and loaded!' })
    }).then(() => {
        console.log("Ghost_HUD: NUI Ready signal sent to client.");
    });
});

function formatMoney(amount) {
    return "$" + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function UpdateHUDPosition(config) {
    const hudContainer = document.getElementById('hud-container');
    hudContainer.style.display = config.hudEnabled ? 'block' : 'none';

    if (!config.hudEnabled) {
        document.querySelectorAll('#clock, #status-hud, #vehicle-hud, #weapon-hud, #topright-hud, .status-item').forEach(el => {
            el.style.display = 'none';
        });
        return;
    }

    const mainElements = {
        'health': 'health',
        'armor': 'armor',
        'hunger': 'hunger',
        'thirst': 'thirst',
        'stamina': 'stamina',
        'stress': 'stress',
        'radiation': 'radiation',
        'temperature': 'temperature',
        'voice': 'voice',
        'vehicle-hud': 'vehicle',
        'weapon-hud': 'weapon',
        'money': 'money',
        'job': 'job',
        'id': 'id',
        'clock': 'clock'
    };

    for (const [elementId, configKey] of Object.entries(mainElements)) {
        const el = document.getElementById(elementId);
        if (el) {
            el.style.display = config.elements[configKey]?.enabled ? 'flex' : 'none';
        }
    }

    // Gerencia a visibilidade do container #topright-hud
    const topRightElements = ['money', 'job', 'id'];
    const isTopRightVisible = topRightElements.some(key => config.elements[key]?.enabled);
    const topRightContainer = document.getElementById('topright-hud');
    if (topRightContainer) {
        topRightContainer.style.display = isTopRightVisible ? 'flex' : 'none';
    }


    // Atualiza elementos de status individuais
    document.querySelectorAll('.status-item').forEach(el => {
        const elementId = el.id;
        if (elementId && config.elements[elementId]) {
            el.style.display = config.elements[elementId].enabled ? 'flex' : 'none';
        }
    });

    // Atualiza exibição dos valores numéricos
    const showValues = config.showValues ?? false;
    document.querySelectorAll('.status-value').forEach(el => {
        el.style.display = showValues ? 'block' : 'none';
        el.style.marginTop = showValues ? '2px' : '0';
    });
        if (!showValues) {
        document.querySelectorAll('.status-item').forEach(item => {
            item.style.alignItems = 'center';
            item.style.justifyContent = 'center';
        });
    }

    // Atualiza minimapa
    fetch(`https://${GetParentResourceName()}/updateMinimap`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            show: config.hudEnabled && config.minimapEnabled 
        })
    });
}

function updateStreetName(streetName) {
    const streetElement = document.getElementById('street-name');
    if (streetElement) {
        streetElement.textContent = streetName;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    // CORREÇÃO: A linha abaixo foi movida para config.js para evitar o erro de referência.
    // document.getElementById('close-config').addEventListener('click', CloseConfig);
    
    // Adiciona efeito de hover nos elementos
    const elements = document.querySelectorAll('.element-toggle');
    elements.forEach(el => {
        el.addEventListener('mouseenter', () => {
            el.style.backgroundColor = 'rgba(255, 255, 255, 0.1)';
        });
        el.addEventListener('mouseleave', () => {
            el.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
        });
    });
});