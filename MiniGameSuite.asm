INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

SW_HIDE EQU 0   ; used to hide the window during instructions for game 2, so user can see both instructions and console at the same time
SW_SHOW EQU 5

;==================== DATA =======================
.data
ErrorTitle  BYTE "Error",0

WindowName  BYTE "HUMAN BENCHMARK (mini)",0
className   BYTE "HBWinClass",0

titleScreen BYTE "=========================================",0dh,0ah,
                 "                          HUMAN BENCHMARK (mini)         ",0dh,0ah,
                 "=========================================",0dh,0ah,0dh,0ah,
                 "Game List",0dh,0ah,
                 "1) Reaction Time",0dh,0ah,
                 "2) Number Memory",0dh,0ah,
                 "3) Mouse Clicker",0dh,0ah,
                 "4) Math Speed Test",0dh,0ah,0

prompt1 BYTE "Check Your Reaction Time",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0
prompt2 BYTE "Number Memory",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0
prompt3 BYTE "Mouse Clicker",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0
prompt4 BYTE "Math Speed Test",0dh,0ah,
              "YES = Play",0dh,0ah,
              "NO = Next Game",0dh,0ah,
              "CANCEL = Exit",0

game1Msg BYTE "Reaction Test Starting...",0
game2Msg BYTE "Number Memory Test Starting...",0
game3Msg BYTE "Game 3 Selected",0
againTitle BYTE "Want to play again?",0

; Reaction Time instructions
game1Inst BYTE "Leave your mouse over the OK button",0dh,0ah,
               "After pressing OK, wait for CLICK NOW!",0dh,0ah,
               "Then click as fast as possible.",0
reactBuffer BYTE "Reaction Time: 0000 ms",0
reactStart DWORD 0
clickNow BYTE "************* CLICK NOW! *************",0dh,0ah,
                " ",0dh,0ah,
                " ",0

; Number Memory instructions
game2Inst BYTE "Remember the numbers displayed.",0dh,0ah,
               "After pressing OK, Click on the console and enter them in order",0dh,0ah,
               "If you get it right, it becomes more challenging.",0dh,0ah,
               "Please resize the console to see this Message and the console at the same time",0dh,0ah,
               "Only follow each button and prompt.",0
correctBuffer BYTE 21 DUP(0)   ; up to 20 digits as max level, plus null terminator
userInput     BYTE 21 DUP(0)
level DWORD 0       ; current level

winMsg     BYTE "You win! 20 digits remembered!",0
loseMsg    BYTE "Game Over!",0dh,0ah,
                "The correct answer was",0
nextMsg    BYTE "Correct! Moving to next level.",0
inputPrompt BYTE "Enter the number: ",0                 ; Console Prompt

; Mouse Clicker instructions
game3Inst BYTE "Click as fast as you can for 5 seconds!",0dh,0ah,
               "Click anywhere else in the window.",0dh,0ah,
               " ",0dh,0ah,
               " ",0dh,0ah,
               " ",0dh,0ah,
               " ",0dh,0ah,
               " ",0            ; multiple blank lines to prevent accidental clicks after results
clickCount DWORD 0
gameActive DWORD 0
clickStart DWORD 0
clickBuffer BYTE "Clicks: 00000",0

; Math Speed Test instructions
mathInst BYTE "Welcome to the Math Speed Test",0dh,0ah,
              "You have 10 questions.",0dh,0ah,
              "Answer as fast as you can.",0dh,0ah,
              "After you select your mode, click on the console",0dh,0ah,
              "The time will start when you see your first question",0
mathType BYTE "Choose Mode:",0dh,0ah,
              "YES = Addition",0dh,0ah,
              "NO = Multiplication",0
mathPrompt BYTE " = ",0
mathTimeBuffer BYTE "Completion Time (seconds): ",0
mathInput BYTE 16 DUP(0)    ; buffer for user input
mathStart DWORD 0       ; start time for math test
mathEnd   DWORD 0       ; end time for math test
mathOp    DWORD 0    ; 0 = add, 1 = multiply
mathA DWORD ?       ; first operand
mathB DWORD ?       ; second operand




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
call Randomize      ; seed random number generator

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

        ; --- Game 4 ---
        INVOKE MessageBox, hWnd, ADDR prompt4,
            ADDR WindowName, MB_YESNOCANCEL
        cmp eax, IDYES
        je option4
        cmp eax, IDCANCEL
        je exit_all

        jmp menu_start      ; loop back around

	option1:
        ; Reaction test setup
        INVOKE MessageBox, hWnd, ADDR game1Inst,
            ADDR WindowName, MB_OK

        ; Random delay between 2-6 seconds
        mov eax, 4000
        call RandomRange    ; returns 0–3999 in eax
        add eax, 2000       ; now 2000–5999 ms
        call Delay          ; pause for that duration

        ; Start timer
        call GetMseconds
        mov reactStart, eax
        
        ; User reacts by pressing OK and ends timer
        INVOKE MessageBox, hWnd, ADDR clickNow,
            ADDR WindowName, MB_OK
        call GetMseconds
        sub eax, reactStart   ; eax = reaction time

        ; Convert to ASCII
        pushad
        mov ecx, 5
        mov ebx, 10
        lea edi, reactBuffer+20   ; last digit position

        convert_react:
        xor edx, edx
        div ebx
        add dl, '0'
        mov [edi], dl
        dec edi
        loop convert_react
        popad

        ; Show result
        INVOKE MessageBox, hWnd, ADDR reactBuffer,
            ADDR WindowName, MB_OK

        ; Ask to play again
        INVOKE MessageBox, hWnd, ADDR againTitle,
            ADDR WindowName, MB_YESNO
        cmp eax, IDYES
        je option1
        cmp eax, IDNO
        je menu_start

    option2:
        INVOKE ShowWindow, hMainWnd, SW_HIDE    ; hide window during instructions so user can see console
        INVOKE MessageBox, hWnd, ADDR game2Inst,
            ADDR WindowName, MB_OK
    
        mov level, 1    ; start at level 1, which is 1 digit to remember

        level_loop:

        ; check win condition, max level is 20
        mov eax, level
        cmp eax, 21
        je win_game

        ; generate number string
        pushad
        mov edi, OFFSET correctBuffer
        mov ecx, level

        get_digits:
        mov eax, 10
        call RandomRange        ; returns 0-9 in eax
        add al, '0'             ; convert to ASCII
        mov [edi], al           ; store digit
        inc edi
        loop get_digits         ; repeat for number of digits in current level
        mov BYTE PTR [edi], 0   ; null terminator
        popad

        ; Show number and Prompt user
        INVOKE MessageBox, hWnd, ADDR correctBuffer,
            ADDR WindowName, MB_OK
        call Clrscr
        mov edx, OFFSET inputPrompt
        call WriteString
        mov edx, OFFSET userInput       ; buffer for user input
        mov ecx, 21
        call ReadString
        mov esi, OFFSET correctBuffer   ; pointer to correct answer
        mov edi, OFFSET userInput       ; pointer to user input to compare

        ; Compare character by character until null terminator
        compare_loop:   
        mov al, [esi]
        mov bl, [edi]
        cmp al, bl
        jne lose_game
        cmp al, 0
        je correct_level
        inc esi
        inc edi
        jmp compare_loop

        ; If we get here, the user was correct
        correct_level:
        INVOKE MessageBox, hWnd, ADDR nextMsg,
            ADDR WindowName, MB_OK
        inc level
        jmp level_loop

        ; If we get here, the user was incorrect
        lose_game:
        INVOKE MessageBox, hWnd, ADDR loseMsg,
            ADDR WindowName, MB_OK
        INVOKE MessageBox, hWnd, ADDR correctBuffer,
            ADDR WindowName, MB_OK
        jmp end_game

        ; If we get here, the user won by reaching level 21 (remembering 20 digits)
        win_game:
        INVOKE MessageBox, hWnd, ADDR winMsg,
            ADDR WindowName, MB_OK

        ; Ask to play again
        end_game:
        INVOKE MessageBox, hWnd, ADDR againTitle,
            ADDR WindowName, MB_YESNO
        cmp eax, IDYES
        je option2
        cmp eax, IDNO
        je menu_start

    option3:
        INVOKE MessageBox, hWnd, ADDR game3Inst,
            ADDR WindowName, MB_OK

        ; initialize game
        mov clickCount, 0
        mov gameActive, 1

        call GetMseconds        ; get start time for click counter
        mov clickStart, eax

        jmp WinProcExit
        
    exit_all:
        INVOKE PostQuitMessage, 0
        jmp WinProcExit

    ; Close window
    .ELSEIF eax == WM_CLOSE
        INVOKE PostQuitMessage, 0
        jmp WinProcExit

    .ELSEIF eax == WM_LBUTTONDOWN
        cmp gameActive, 1   ; only count clicks if game is active
        jne skip_click      ; if not active, skip counting and time check

        inc clickCount
        call GetMseconds
        mov ebx, eax
        sub ebx, clickStart ; check elapsed time
        cmp ebx, 5000       ; if more than 5 seconds, end game
        jl skip_click       ; if less than 5 seconds, keep counting
        mov gameActive, 0   ; time's up

        ; Convert click count to ASCII
        pushad
        mov eax, clickCount
        mov ecx, 5
        mov ebx, 10
        lea edi, clickBuffer+12   ; end of digits

        convert_clicks:
            xor edx, edx
            div ebx
            add dl, '0'
            mov [edi], dl
            dec edi
            loop convert_clicks
        popad

        ; Show result
        INVOKE MessageBox, hWnd, ADDR clickBuffer,
            ADDR WindowName, MB_OK

        ; Play again
        INVOKE MessageBox, hWnd, ADDR againTitle,
            ADDR WindowName, MB_YESNO
        cmp eax, IDYES
        je option3
        cmp eax, IDNO
        je menu_start

    skip_click:
        jmp WinProcExit

    option4:
        INVOKE ShowWindow, hMainWnd, SW_HIDE    ; hide window during instructions so user can see console
        INVOKE MessageBox, hWnd, ADDR mathInst,
            ADDR WindowName, MB_OK
        INVOKE MessageBox, hWnd, ADDR mathType,
            ADDR WindowName, MB_YESNO

        cmp eax, IDYES
        je set_add
        mov mathOp, 1       ; multiplication
        jmp type_done

        set_add:
            mov mathOp, 0   ; addition

        type_done:
            mov eax, 3000   ; Pause before starting to let user get ready
            call Delay
            call Clrscr
            call GetMseconds
            mov mathStart, eax      ; start timer right before first question
            mov ebx, 10             ; Question counter
        
        math_loop:
            mov eax, 10
            call RandomRange
            mov mathA, eax          ; first operand, 0-9
            mov eax, 10
            call RandomRange
            mov mathB, eax          ; second operand, 0-9
        
        ask_question:
            mov eax, mathA          ; print first operand
            call WriteDec
            cmp mathOp, 0           ; check operation type
            je print_add
            mov al, '*'             ; print multiplication operator
            call WriteChar
            jmp print_b
        
        print_add:
            mov al, '+'             ; print addition operator
            call WriteChar
        
        print_b:
            mov eax, mathB          ; print second operand
            call WriteDec
        
            mov edx, OFFSET mathPrompt  ; print equals sign and prompt for answer
            call WriteString
        
            ; Clear input buffer
            mov edi, OFFSET mathInput
            mov ecx, 16
            mov al, 0
            rep stosb       ; fill mathInput with null terminators to clear any previous input
        
            ; Read user input as string
            mov edx, OFFSET mathInput
            mov ecx, 16
            call ReadString
        
            ; Convert user input from ASCII to integer
            mov esi, OFFSET mathInput
            xor eax, eax
        
        convert_input:
            mov dl, [esi]       ; get next character
            cmp dl, 0
            je done_convert
        
            cmp dl, '0'         ; check if character is a valid digit
            jb done_convert
            cmp dl, '9'
            ja done_convert
        
            sub dl, '0'         ; convert ASCII to numeric value
            movzx edx, dl
            imul eax, 10        ; shift previous digits left by multiplying by 10
            add eax, edx
        
            inc esi             ; move to next character
            jmp convert_input
        
        done_convert:
            ; Calculate correct answer
            mov edx, mathA
            mov ecx, mathB
            cmp mathOp, 0       ; check if addition or multiplication
            je add_case
        
            imul edx, ecx
            jmp check_ans
        
        add_case:
            add edx, ecx
        
        check_ans:
            cmp eax, edx        ; compare user answer to correct answer
            jne ask_question
            call Clrscr
            dec ebx             ; decrement question counter
            jnz math_loop       ; if more questions, ask next one
        
            
            call GetMseconds    ; end timer after last question
            mov mathEnd, eax
            sub eax, mathStart
        
            ; Convert time to seconds and ASCII
            mov ecx, 1000       ; convert milliseconds to seconds
            xor edx, edx
            div ecx
            pushad      
            mov ecx, 5
            mov ebx, 10
            lea edi, reactBuffer+20
            convert_math_time:
                xor edx, edx
                div ebx
                add dl, '0'
                mov [edi], dl
                dec edi
                loop convert_math_time
            popad
        
            ; Show result
            INVOKE MessageBox, hWnd, ADDR mathTimeBuffer,
                ADDR WindowName, MB_OK
        
            ; Ask to play again
            INVOKE MessageBox, hWnd, ADDR againTitle,
                ADDR WindowName, MB_YESNO
            cmp eax, IDYES
            je option4
            cmp eax, IDNO
            je menu_start
    
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

COMMENT @
On google search: SW_HIDE, Hides the window and activates another window ... 
Zero indicates that the window was previously hidden.
@
