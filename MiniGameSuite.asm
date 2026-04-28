INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

WM_KEYDOWN EQU 0100h
WM_KEYUP   EQU 0101h
WM_CHAR    EQU 0102h

;==================== DATA =======================
.data
ErrorTitle  BYTE "Error",0

WindowName  BYTE "Human Benchmark Clone",0
className   BYTE "HBWinClass",0

titleScreen BYTE "==============================",0dh,0ah,
                 "      HUMAN BENCHMARK        ",0dh,0ah,
                 "==============================",0dh,0ah,0dh,0ah,
                 "1) Reaction Time",0dh,0ah,
                 "2) Game Two",0dh,0ah,
                 "3) Game Three",0dh,0ah,0dh,0ah,0

prompt1 BYTE "Check Your Reaction Time?",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0

prompt2 BYTE "Game Two?",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0

prompt3 BYTE "Game Three?",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Back to Start",0dh,0ah,
              "CANCEL = Exit",0

reactMsg BYTE "Reaction Test Starting...",0
game2Msg BYTE "Game 2 Selected",0
game3Msg BYTE "Game 3 Selected",0

; Reaction instructions
reactInst BYTE "Keep your mouse over the window.",0dh,0ah,
               "After pressing OK, wait for CLICK NOW!",0dh,0ah,
               "Then click as fast as possible.",0

resultBuffer BYTE "Reaction Time: 0000 ms",0

; Large visual titles
clickTitle BYTE "***** CLICK NOW! *****",0
againTitle BYTE "Want to play again?",0

; Timing
startTime DWORD 0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

;=================== CODE =========================
.code
WinMain PROC
; Get a handle to the current process.
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Show and draw the window.
	INVOKE ShowWindow, hMainWnd, SW_SHOW
	INVOKE UpdateWindow, hMainWnd

; Begin the program's message-handling loop.
Message_Loop:
	; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
	  INVOKE ExitProcess,0
WinMain ENDP


WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
	mov eax, localMsg

    ; When window is created
    .IF eax == WM_CREATE
        INVOKE MessageBox, hWnd, ADDR titleScreen,
            ADDR WindowName, MB_OK

    menu_start:
        ; --- Game 1 ---
        INVOKE MessageBox, hWnd, ADDR prompt1,
            ADDR WindowName, MB_YESNOCANCEL
        cmp eax, IDYES
        je option1
        cmp eax, IDCANCEL
        je exit_all

        ; --- Game 2 ---
        INVOKE MessageBox, hWnd, ADDR prompt2,
            ADDR WindowName, MB_YESNOCANCEL
        cmp eax, IDYES
        je option2
        cmp eax, IDCANCEL
        je exit_all

        ; --- Game 3 ---
        INVOKE MessageBox, hWnd, ADDR prompt3,
            ADDR WindowName, MB_YESNOCANCEL
        cmp eax, IDYES
        je option3
        cmp eax, IDCANCEL
        je exit_all

        jmp menu_start

	option1:
        ; Reaction test setup
        INVOKE MessageBox, hWnd, ADDR reactInst,
            ADDR WindowName, MB_OK

        ; WAIT phase
        ; Random delay between 3-6 seconds
        mov eax, 3000
        call RandomRange    ; returns 0–2999 in eax
        add eax, 3000       ; now 3000–5999 ms
        call Delay          ; pause for that duration

        call GetMseconds
        mov startTime, eax
        
        ; User reacts by pressing OK
        INVOKE MessageBox, hWnd, ADDR clickTitle,
            ADDR WindowName, MB_OK
        
        call GetMseconds
        sub eax, startTime   ; eax = reaction time

       ; Convert to ASCII
    pushad
    mov ecx, 5
    mov ebx, 10
    lea edi, resultBuffer+20   ; last digit position

    convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [edi], dl
    dec edi
    loop convert_loop
    popad

        ; First message: show result
        INVOKE MessageBox, hWnd, ADDR resultBuffer,
            ADDR WindowName, MB_OK

        ; Second message: ask to play again
        INVOKE MessageBox, hWnd, ADDR againTitle,
            ADDR WindowName, MB_YESNOCANCEL

        cmp eax, IDYES
        je option1
        cmp eax, IDNO
        je menu_start

    option2:
        INVOKE MessageBox, hWnd, ADDR game2Msg,
            ADDR WindowName, MB_OK
        INVOKE PostQuitMessage, 0
        jmp WinProcExit

    option3:
        INVOKE MessageBox, hWnd, ADDR game3Msg,
            ADDR WindowName, MB_OK
        INVOKE PostQuitMessage, 0
        jmp WinProcExit
        

    exit_all:
        INVOKE PostQuitMessage, 0
        jmp WinProcExit

    ; Close window
    .ELSEIF eax == WM_CLOSE
        INVOKE PostQuitMessage, 0
        jmp WinProcExit

    ; Default behavior
    .ELSE
        INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
        jmp WinProcExit
    .ENDIF

WinProcExit:
	ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

END WinMain
