INCLUDE Irvine32.inc
.386
.model flat,stdcall
.stack 4096
ExitProcess proto,dwExitCode:dword

.data
fib DWORD 7 DUP(?)

.code
main PROC

    mov fib[0], 1
    mov fib[4], 1

    mov eax, fib[0]        ; Fib(n-2)
    mov ebx, fib[4]        ; Fib(n-1)
    mov ecx, 5        ; need 5 more values

    mov esi, 2        ; index

L1:
    mov edx, eax
    add edx, ebx      ; edx = next Fibonacci

    mov fib[esi*4], edx

    mov eax, ebx
    mov ebx, edx

    inc esi
    loop L1

    invoke ExitProcess,0
main ENDP
END main