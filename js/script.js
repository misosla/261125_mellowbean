// 메뉴를 누르면 그 구역으로 부드럽게 이동합니다.

// 주소가 #으로 시작하는 링크를 모두 찾습니다.
const links = document.querySelectorAll('a[href^="#"]');

// 컴퓨터에서 "움직임 줄이기"를 켜둔 사람인지 확인합니다.
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

links.forEach(function (link) {
  link.addEventListener('click', function (event) {
    event.preventDefault();  // 한 번에 휙 이동하는 기본 동작을 막습니다.

    const target = document.querySelector(link.getAttribute('href'));
    target.scrollIntoView({ behavior: reduceMotion.matches ? 'auto' : 'smooth' });
  });
});
