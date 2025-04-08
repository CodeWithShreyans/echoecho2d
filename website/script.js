document.addEventListener("DOMContentLoaded", function () {
	const navLinks = document.querySelectorAll("nav ul li a");

	navLinks.forEach((link) => {
		link.addEventListener("click", function (e) {
			e.preventDefault();
			const targetId = this.getAttribute("href");
			const targetSection = document.querySelector(targetId);

			window.scrollTo({
				top: targetSection.offsetTop - 80,
				behavior: "smooth",
			});
		});
	});

	const logo = document.querySelector(".logo");
	const waveAnimation = document.querySelector(".wave-animation");

	logo.addEventListener("mouseenter", function () {
		waveAnimation.style.animation = "none";
		setTimeout(() => {
			waveAnimation.style.animation = "wave-pulse 1.5s infinite";
		}, 10);
	});

	const playerShip = document.querySelector(".player-ship");
	if (playerShip) {
		setInterval(() => {
			const randomRotation = Math.random() * 10 - 5;
			playerShip.style.transform = `translate(-50%, -50%) rotate(${randomRotation}deg)`;
		}, 2000);
	}

	window.addEventListener("scroll", function () {
		const scrollPosition = window.scrollY;

		document.querySelector(".stars").style.transform = `translateY(${
			scrollPosition * 0.1
		}px)`;
		document.querySelector(".twinkling").style.transform = `translateY(${
			scrollPosition * 0.2
		}px)`;

		const enemyAstronaut = document.querySelector(".enemy-astronaut");
		if (enemyAstronaut) {
			enemyAstronaut.style.transform = `translateY(-${
				scrollPosition * 0.05
			}px) rotate(${scrollPosition * 0.02}deg)`;
		}
	});

	const heroHeading = document.querySelector(".hero-content h2");
	if (heroHeading) {
		const text = heroHeading.textContent;
		heroHeading.textContent = "";

		let i = 0;
		const typingEffect = setInterval(() => {
			if (i < text.length) {
				heroHeading.textContent += text.charAt(i);
				i++;
			} else {
				clearInterval(typingEffect);
			}
		}, 50);
	}

	const cursorTrail = document.createElement("div");
	cursorTrail.classList.add("cursor-trail");
	document.body.appendChild(cursorTrail);

	let mouseX = 0,
		mouseY = 0;
	let trailX = 0,
		trailY = 0;

	document.addEventListener("mousemove", (e) => {
		mouseX = e.clientX;
		mouseY = e.clientY;
	});

	const animateCursor = () => {
		trailX += (mouseX - trailX) * 0.1;
		trailY += (mouseY - trailY) * 0.1;

		cursorTrail.style.left = `${trailX}px`;
		cursorTrail.style.top = `${trailY}px`;

		requestAnimationFrame(animateCursor);
	};

	animateCursor();

	const style = document.createElement("style");
	style.textContent = `
        .cursor-trail {
            position: fixed;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(0,240,255,0.7) 0%, rgba(0,240,255,0) 70%);
            pointer-events: none;
            z-index: 9999;
            transform: translate(-50%, -50%);
            transition: width 0.3s, height 0.3s;
            box-shadow: 0 0 10px rgba(0, 240, 255, 0.5);
        }
    `;
	document.head.appendChild(style);

	const buttons = document.querySelectorAll(
		".cta-button, .contact-button, .download-button",
	);
	buttons.forEach((button) => {
		button.addEventListener("mouseenter", () => {
			cursorTrail.style.width = "50px";
			cursorTrail.style.height = "50px";
		});

		button.addEventListener("mouseleave", () => {
			cursorTrail.style.width = "20px";
			cursorTrail.style.height = "20px";
		});
	});

	setInterval(() => {
		const wave = document.createElement("div");
		wave.classList.add("background-wave");

		const posX = Math.random() * window.innerWidth;
		const posY = Math.random() * window.innerHeight;

		wave.style.left = `${posX}px`;
		wave.style.top = `${posY}px`;

		document.body.appendChild(wave);

		setTimeout(() => {
			wave.remove();
		}, 2000);
	}, 5000);

	const waveStyle = document.createElement("style");
	waveStyle.textContent = `
        .background-wave {
            position: fixed;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            border: 2px solid var(--primary-color);
            z-index: -5;
            opacity: 0;
            animation: bg-wave-pulse 2s ease-out forwards;
        }
        
        @keyframes bg-wave-pulse {
            0% {
                width: 10px;
                height: 10px;
                opacity: 0.8;
            }
            100% {
                width: 500px;
                height: 500px;
                opacity: 0;
            }
        }
    `;
	document.head.appendChild(waveStyle);

	const gameTitle = document.querySelector(".logo h1");
	if (gameTitle) {
		setInterval(() => {
			gameTitle.classList.add("glitch");

			setTimeout(() => {
				gameTitle.classList.remove("glitch");
			}, 200);
		}, 5000);
	}

	const glitchStyle = document.createElement("style");
	glitchStyle.textContent = `
        @keyframes glitch {
            0% {
                transform: translate(0);
            }
            20% {
                transform: translate(-3px, 3px);
            }
            40% {
                transform: translate(-3px, -3px);
            }
            60% {
                transform: translate(3px, 3px);
            }
            80% {
                transform: translate(3px, -3px);
            }
            100% {
                transform: translate(0);
            }
        }
        
        .glitch {
            animation: glitch 0.2s linear infinite;
            text-shadow: 
                2px 0 var(--primary-color), 
                -2px 0 var(--secondary-color);
        }
    `;
	document.head.appendChild(glitchStyle);

	const createMobileNav = () => {
		const header = document.querySelector("header");
		const nav = document.querySelector("nav");

		const menuToggle = document.createElement("button");
		menuToggle.classList.add("menu-toggle");
		menuToggle.innerHTML = "☰";

		header.insertBefore(menuToggle, nav);

		menuToggle.addEventListener("click", () => {
			nav.classList.toggle("active");
			menuToggle.textContent = nav.classList.contains("active") ? "✕" : "☰";
		});
	};

	if (window.innerWidth < 768) {
		createMobileNav();
	}

	const mobileNavStyle = document.createElement("style");
	mobileNavStyle.textContent = `
        @media (max-width: 768px) {
            .menu-toggle {
                display: block;
                background: none;
                border: none;
                color: var(--text-color);
                font-size: 1.5rem;
                cursor: pointer;
                z-index: 1001;
                position: absolute;
                top: 1rem;
                right: 1rem;
            }
            
            nav {
                position: fixed;
                top: 0;
                right: -100%;
                width: 70%;
                height: 100vh;
                background-color: rgba(5, 5, 32, 0.95);
                display: flex;
                align-items: center;
                justify-content: center;
                transition: right 0.3s ease;
            }
            
            nav.active {
                right: 0;
            }
            
            nav ul {
                flex-direction: column;
                align-items: center;
            }
            
            nav ul li {
                margin: 1rem 0;
            }
        }
    `;
	document.head.appendChild(mobileNavStyle);

	const konamiCode = [
		"ArrowUp",
		"ArrowUp",
		"ArrowDown",
		"ArrowDown",
		"ArrowLeft",
		"ArrowRight",
		"ArrowLeft",
		"ArrowRight",
		"b",
		"a",
	];
	let konamiIndex = 0;

	document.addEventListener("keydown", (e) => {
		if (e.key === konamiCode[konamiIndex]) {
			konamiIndex++;

			if (konamiIndex === konamiCode.length) {
				konamiIndex = 0;

				for (let i = 0; i < 20; i++) {
					setTimeout(() => {
						const wave = document.createElement("div");
						wave.classList.add("konami-wave");

						const posX = Math.random() * window.innerWidth;
						const posY = Math.random() * window.innerHeight;

						wave.style.left = `${posX}px`;
						wave.style.top = `${posY}px`;

						document.body.appendChild(wave);

						setTimeout(() => {
							wave.remove();
						}, 2000);
					}, i * 100);
				}
			}
		} else {
			konamiIndex = 0;
		}
	});

	const konamiStyle = document.createElement("style");
	konamiStyle.textContent = `
        .konami-wave {
            position: fixed;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            border: 2px solid var(--accent-color);
            z-index: 9999;
            opacity: 0;
            animation: konami-wave-pulse 2s ease-out forwards;
        }
        
        @keyframes konami-wave-pulse {
            0% {
                width: 10px;
                height: 10px;
                opacity: 0.8;
                border-color: var(--accent-color);
            }
            50% {
                border-color: var(--secondary-color);
            }
            100% {
                width: 300px;
                height: 300px;
                opacity: 0;
                border-color: var(--primary-color);
            }
        }
    `;
	document.head.appendChild(konamiStyle);
});
