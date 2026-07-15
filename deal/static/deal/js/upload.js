document.addEventListener('DOMContentLoaded', () => {
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    const previews = [
        document.getElementById('preview-1'),
        document.getElementById('preview-2')
    ];

    if (!dropZone || !fileInput) return;

    // 테두리 스타일을 초기화하거나 하이라이트하는 헬퍼 함수
    function setHighlight(isHighlighted) {
        if (isHighlighted) {
            // 회색 테두리 제거하고 보라/인디고 테두리 추가
            dropZone.classList.remove('border-gray-200', 'dark:border-gray-700');
            dropZone.classList.add('border-violet-500', 'dark:border-indigo-500');
        } else {
            // 보라/인디고 테두리 제거하고 회색 테두리 원복
            dropZone.classList.remove('border-violet-500', 'dark:border-indigo-500');
            dropZone.classList.add('border-gray-200', 'dark:border-gray-700');
        }
    }

    // 1. 드래그 할 때 테두리 하이라이트 활성화
    ['dragenter', 'dragover'].forEach(eventName => {
        dropZone.addEventListener(eventName, (e) => {
            e.preventDefault();
            setHighlight(true);
        }, false);
    });

    // 2. 드래그 구역을 벗어나거나 드롭했을 때 테두리 원복
    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, (e) => {
            e.preventDefault();
            setHighlight(false);
        }, false);
    });

    // 3. 이미지를 드롭 구역에 놓았을 때(Drop) 처리
    dropZone.addEventListener('drop', (e) => {
        const dt = e.dataTransfer;
        const files = dt.files;

        if (files.length > 0) {
            fileInput.files = files; // 드래그한 파일을 input에 주입
            handleFiles(files);
            setHighlight(true); // 파일이 들어왔으므로 활성화 고정
        }
    });

    // 4. 이미지 등록 버튼을 클릭해서 파일 탐색기로 정상 첨부했을 때 처리
    fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            handleFiles(e.target.files);
            setHighlight(true); // 파일이 선택되었으므로 테두리 변경
        } else {
            setHighlight(false);
        }
    });

    // 5. 파일 읽어서 미리보기 창에 꽂아넣는 함수
    function handleFiles(files) {
    // 기존 글자 리셋
    if (previews[0]) previews[0].innerHTML = '';
    if (previews[1]) previews[1].innerHTML = '';

    const maxFiles = Math.min(files.length, previews.length);
    
    for (let i = 0; i < maxFiles; i++) {
        const file = files[i];
        if (!previews[i] || !file.type.startsWith('image/')) continue;

        const reader = new FileReader();
        reader.onload = (e) => {
            // 🛠️ 수정: 이미지 태그에 가로/세로 100%, 꽉 차게 채우는(object-cover) 스타일 직접 강제 주입
            const imgTag = document.createElement('img');
            imgTag.src = e.target.result;
            imgTag.style.width = '100%';
            imgTag.style.height = '100%';
            imgTag.style.objectFit = 'cover';
            
            // 기존 미리보기 박스 안에 정렬하여 꽂아넣기
            previews[i].appendChild(imgTag);
        };
        reader.readAsDataURL(file);
    }
}
});