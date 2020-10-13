section .bss
    stack: resd 1
    input_ptr: resb 81
    size: resb 1

section .rodata
    newLine: db 10 , 0 ;
    hexFormat: db "%X", 0
    nullTerminator: db 0
    stringFormat: db "%s", 10, 0
    numberFormat: db "%d", 0
    calcMsg: db "calc: ", 0
    overflowMsg: db "Error: Operand Stack Overflow", 10, 0
    illegalPopMsg: db "Error: Insufficient Number of Arguments on Stack", 10 , 0

section .data
    debug: db 0
    flagForN: db 0
    stackSize: db 5
    itemsCounter: db 0
    operationsCounter: dd 0 ;
    freeNode: dd 0 ;
    summerizeCounter: dd 0;
    freeNode2: dd 0 ;

section .text
    align 16
    global main
    extern fprintf
    extern printf
    extern calloc
    extern free
    extern stdout
    extern stderr
    extern getchar
    extern fgets
    extern fflush
    extern malloc

%macro putZeroes 0
	and eax, 0x0000FFFF
%endmacro

%macro putValueIn 2
push eax
backupRegs
push word %2
call hexStringToByte
add esp,1
add esp,1
restoreRegs
mov %1, al
pop eax
%endmacro


%macro sumUpNodes 0
	popfd
	mov byte dl,[ebx]
	mov byte [eax], dl
	backupRegs
	restoreRegs
	mov byte dl,[ecx]
	adc byte [eax], dl
	pushfd
%endmacro


%macro countDigitsAdd 1
    backupRegs
    call countDigitCreateNode
    restoreRegs
	mov byte [eax], %1
	backupRegs
	restoreRegs
	mov byte [flagForN], 1
    backupRegs
    call summerize
	restoreRegs
	mov byte [flagForN], 0
	add dword [operationsCounter] , -1 ;
%endmacro



%macro printDebug 1
    pushad
    push dword %1
    push dword stringFormat
    push dword [stderr]
    call fprintf
    add esp, 4
    add esp, 8
    push dword [stderr]
    call fflush
    add esp, 4
    popad
%endmacro




%macro newlineToNull 0
    pushad
    mov esi, input_ptr
    loopNull:
        cmp byte [esi], 10
        je endNullLoop
        add esi, 1
        jmp loopNull
    endNullLoop:
    mov byte [esi], 00
    mov byte [esi], 00
    popad
%endmacro


%macro backupRegs 0
    push edx
    push ecx
    push ebx
    push esi
    push edi
    push ebp
%endmacro

%macro restoreRegs 0
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop ecx
    pop edx
%endmacro

%macro print 1
pushad
push %1
call printf
add esp, 4
push dword [stdout]
call fflush
add esp, 4
popad
%endmacro

%macro print 2
pushad
push %1
call printf
add esp, 4
push dword %2
call fflush
add esp, 4
popad
%endmacro

%macro setDebugFlag 0
  mov byte [debug], 1
%endmacro




%macro printDebugOutput 0
    pushad
    mov ebx, [stack]
    mov edx, 0
    mov dl, [itemsCounter]
    dec dl
    push dword [stderr]
    push dword [ebx + edx * 4]
    call popRec
    add esp, 8
    print newLine, [stderr]
    print nullTerminator, [stderr]
    popad
%endmacro



%macro readToBuffer 0
        mov eax, 3
        mov ebx, 0
        mov ecx, input_ptr
        mov edx, 81
        int 0x80
%endmacro

main:
    mov ebp, esp

    mov ebx, [esp+8] ;
    mov ecx, [esp+4] ;

    add ebx, 4
    cmp ecx, 1
    je callCalculator
    add ecx , -1

    checkArguments:

        mov edx, [ebx]
        mov edx, [edx]

        isDebug:
            and edx, 0x00FFFFFF
            cmp edx, 0x0000642D
            jne findSize
			setDebugFlag
            jmp endCheckArguments

        findSize:
            putValueIn [stackSize], dx

        endCheckArguments:
            add ebx, 4
            add ecx, -1
            jnz checkArguments


    callCalculator:
        backupRegs
        call calculator
        restoreRegs

    pushad
    push eax
    push hexFormat
    call printf
    add esp, 4
    add esp, 4
    popad
    print newLine
    print nullTerminator

    finishProgram:
        mov esp, ebp
        mov eax, 0 ;
        ret

calculator:
    mov eax, 4
    push eax
    add dword [stackSize], 1
    mov eax, [stackSize]

    add dword [stackSize], -1
    push eax
    call calloc
    add esp, 4
    add esp, 4
    mov dword[stack], eax

    calculatorLoop:
        print calcMsg
        print nullTerminator
        backupRegs
		readToBuffer
        restoreRegs
        newlineToNull

    calcCallOperation:
        add eax, -1
		mov dword ebx, [input_ptr]
        cmp byte [input_ptr], 'q'
        je endCalcLoop
        cmp byte [input_ptr], 'p'
        je p
        cmp byte [input_ptr], '+'
        je plus
        cmp byte [input_ptr], 'd'
        je d
        cmp byte [input_ptr], 'n'
        je n
        cmp byte [input_ptr], '&'
        je and
        cmp byte [input_ptr], '|'
        je or
        jmp num


    p:
    	backupRegs
			call popFromStack
			restoreRegs
            jmp calculatorLoop

     plus:
     			backupRegs
			call summerize
			restoreRegs
            jmp calculatorLoop

     d:
     			backupRegs
			call dupLastNumber
			restoreRegs
            jmp calculatorLoop
      n:
      			backupRegs
		    call countDigits
            restoreRegs
            jmp calculatorLoop
     and:
     			backupRegs
			call bitwiseAnd
			restoreRegs
            jmp calculatorLoop
     or:
                 backupRegs
            call bitwiseOr
            restoreRegs
            jmp calculatorLoop


    num:
            push eax
            call putNumInStack
            add esp, 4

            jmp calculatorLoop

    endCalcLoop:
        mov eax, [operationsCounter]
        ret
popRec:
    mov ebp, esp
    push dword 0

    mov ebx, ebp
    add ebx, 4
    mov ebx, [ebx]
    mov cx, [ebx]
    mov edx, [ebx + 1]
    cmp edx, 0
    je lastRec

    backupRegs
    push dword [ebp+8]
    push edx
    call popRec
    add esp, 8
    restoreRegs

    printNode:
        backupRegs
        push cx
        call byteToHexString
        add esp, 2
        restoreRegs

        putZeroes
        mov [ebp-4], eax
        mov edx, ebp
        add edx, -4
        print edx, [ebp+8]

    mov esp, ebp
    ret

popFromStack:
    mov ebp, esp
    add dword [operationsCounter], 1

	backupRegs
    call popnumFromStack
    restoreRegs

    cmp eax, 0
    jle endPop
    mov ecx, eax

    pushad
    push dword [stdout]
    push ecx
    call popRec
    add esp, 8
    popad

    print newLine
    print nullTerminator


    endPop:
        mov esp, ebp
        ret



    lastRec:
			backupRegs
			push cx
			call byteToHexString
			add esp, 2
			restoreRegs

			putZeroes
			cmp al, 48
			je printDigitFromNode

			mov [ebp-4], eax
			mov ecx, ebp
			add ecx, -4
			print ecx, [ebp+8]
			jmp lastRecEnd

        printDigitFromNode:
            shr eax, 4
            backupRegs
			restoreRegs
            shr eax, 4
            mov [ebp-4], eax
            mov ecx, ebp
            add ecx, -4
            print ecx, [ebp+8]

        lastRecEnd:
            mov esp, ebp
            ret



    dupLoop:
        mov edx, eax
        add edx, 1
        mov eax, [ebx]
        dec edx
        mov [edx], eax

        mov ebx, [ebx + 1]
        cmp ebx, 0
        je dupEndDebug

        backupRegs
        call allocateNode
        restoreRegs
        mov [edx + 1], eax
        mov edx, eax
        jmp dupLoop

    dupEndDebug:
        cmp byte [debug], 1
		jne dupEnd
		backupRegs
		;call func
		restoreRegs
		printDebugOutput

    dupEnd:
        mov esp, ebp
        ret

countDigits:
    mov ebp, esp
    add dword [operationsCounter], 1

	backupRegs
    call popnumFromStack
	restoreRegs

    cmp eax, 0
    je countDigitsEnd
    mov ebx, eax
    mov edx, eax


    backupRegs
    call createNewNode
    restoreRegs


    countDigitsLoop:
        cmp dword [ebx + 1], 0
        je countDigitsLastLoop

        countDigitsAdd 2

        mov ebx, [ebx + 1]
        cmp ebx, 0
        jne countDigitsLoop

    countDigitsLastLoop:
		backupRegs
		mov ecx, 16
        cmp [ebx], ecx
        jb countDigitsPlusOne
        restoreRegs
        countDigitsAdd 1

        countDigitsPlusOne:
        countDigitsAdd 1

    	cmp byte [debug], 1
		jne countDigitsEnd
		printDebugOutput

    countDigitsEnd:
        mov esp, ebp
        ret

dupLastNumber:
    mov ebp, esp
    add dword [operationsCounter], 1

	backupRegs
	call popnumFromStack
	restoreRegs
    cmp eax, 0
    je dupEnd

    mov ebx, eax
    backupRegs
    push ebx
    call pushToStack
    add esp, 4
    restoreRegs

    backupRegs
    call createNewNode
    restoreRegs
    cmp eax, 0
    je dupEnd

putNumInStack:
    mov ebp, esp

    cmp byte [debug], 1
    jne notDebug
    printDebug input_ptr

    notDebug:
                backupRegs
           call createNewNode

            restoreRegs
    cmp eax, 0
    je pushHexStringNumberEnd

    mov edx, eax

    pushHexStringNumberStart:
        backupRegs
        call countLeadingZeros
        restoreRegs

    convertBufferToNodes:
    mov ecx, [ebp+4]
    mov ebx, eax
    sub ecx, ebx

    cmp ecx, 0
    je pushHexStringNumberEnd

    convertBufferLoop:
        cmp ecx, 1
        je convertSingleCharFromBuffer
        putValueIn  [edx], [input_ptr + ebx + ecx - 2]
        add ecx, -2
        cmp ecx, 0
        jz pushHexStringNumberEnd
		backupRegs
		call allocateNode
		restoreRegs
        mov [edx + 1], eax
        mov edx , 1
        mov edx, eax
        jmp convertBufferLoop

    convertSingleCharFromBuffer:
        mov bx, [input_ptr + ebx]
        shl bx, 8
        putValueIn  [edx], bx

    pushHexStringNumberEnd:
    	backupRegs
		;func to check
		restoreRegs
        ret

countLeadingZeros:
		mov ebx, input_ptr
		mov eax, 0
    countLeadingZerosLoop:
        cmp byte [ebx + eax], 48
        jne endCountLeadingZeros
        inc eax
        jmp countLeadingZerosLoop
    endCountLeadingZeros:
        ret

hexStringToByte:
    mov ebp, esp
    mov dx, [ebp+4]
    push dx
    call hexCharToValue

    shr dx, 8
    cmp dl, 0
    backupRegs
    restoreRegs
    jz returnStringValue
    shl al, 4
    mov cl , 1
    mov cl, al
    push dx
    call hexCharToValue

    add al, cl

    returnStringValue:
        mov esp, ebp
        ret



byteToHexString:
    mov ebp, esp
    mov dx, [esp+4]
    push dx
    call nibbleToHexChar
    mov ch , 1
    mov ch, al
    backupRegs
    restoreRegs
    shr dx, 4
    push dx
    call nibbleToHexChar
    mov cl, 1
    mov cl, al

    mov ax, cx
    mov esp, ebp
    ret

    hexCharToValue:
	add ebx , 1
    mov al, [esp+4]
    add al, -48
    dec ebx
    cmp al, 9
    jle returnCharValue

    add al, -7
    returnCharValue: ret


nibbleToHexChar:
	mov al, 1
	;check
    mov al, [esp+4]
    and al, 15
    cmp al, 10
    jl addDecimalAsciiOffset
    backupRegs
    restoreRegs
    add al, 7
    addDecimalAsciiOffset:
    mov bl , 48
    add al, bl
    ret


allocateNode:
    push dword 1
    push dword 5
    call calloc

    add esp, 8
    ret


createNewNode:
    mov ebp, esp
    backupRegs
    call allocateNode
    restoreRegs
    mov edx, eax

    backupRegs
    push edx
    call pushToStack
    add esp, 4
    restoreRegs

    cmp eax, 0
    jz failToCreateNode
    mov eax, edx
    ret

    failToCreateNode:

    mov eax, 0
    ret




pushToStack:
    mov eax, 0
    mov al, [itemsCounter]
    cmp [stackSize], al
    je pushFailed

pushNode:
	mov eax, 0
	mov al, [itemsCounter]

	mov ebx, [esp+4]
	mov ecx, [stack]
	add ecx, eax
	add ecx, eax
	add ecx, eax
	add ecx, eax
	mov [ecx], ebx
	inc byte [itemsCounter]
	mov eax, 1
	ret

pushFailed:
	print overflowMsg
	print nullTerminator
	mov eax, 0
	ret


pop2Items:
    mov ebp, esp

	backupRegs
    call popnumFromStack
	restoreRegs
    cmp eax, 0
    je pop2ItemsEnd
    mov ebx , eax
    mov ebx , ebx

	backupRegs
    call popnumFromStack
	restoreRegs

    cmp eax, 0
    jne pop2ItemsEnd


    backupRegs
    mov ecx, ebx
    push ecx
    call pushToStack
    add esp, 4
    restoreRegs

    mov eax, 0
    ret

    pop2ItemsEnd:
        mov esp, ebp
        ret

countDigitCreateNode:
                backupRegs
           call allocateNode

            restoreRegs
    mov edx, eax

    backupRegs
    push edx
    call pushNode
    mov ebx , 1
    add esp, 4
    restoreRegs
    mov eax, edx
    ret

bitwiseOr:
    mov ebp, esp
    add dword [operationsCounter], 1

    push ebp
    call pop2Items
    pop ebp
    cmp eax, 0
    je bitwiseOrEnd

    mov ecx, eax


	backupRegs
    call createNewNode

	restoreRegs
    orLoop:

        mov dl, [ebx]
        mov [eax], dl
        mov dl, [ecx]
        or [eax], dl

		jmp goToNextNode

		checkForFinish:
        cmp ebx, 0
        je orLastLoop

        cmp ecx, 0
        je flipper

        mov edx, eax
		backupRegs
	    call allocateNode
	    mov ebx , 1
		restoreRegs

        mov [edx + 1], eax
        jmp orLoop

    flipper:
        mov edx, ebx
        inc edx
        mov ebx, ecx
        mov ebx, ebx
        ;add  edx , 1
        dec edx
        mov ecx, edx

    orLastLoop:
        cmp ecx, 0
        je orEnd
        je orEnd

        mov edx, eax
        backupRegs
        call allocateNode
        restoreRegs

        mov [edx + 1], eax
        mov dl, [ecx]
        mov dl , dl
        mov [eax], dl
        mov ecx, [ecx + 1]

        jmp orLastLoop

    orEnd:
		cmp byte [debug], 1
		jne bitwiseOrEnd
		printDebugOutput

    bitwiseOrEnd:
        mov esp, ebp
        ret

    goToNextNode:
		inc edx
        mov ebx, [ebx + 1]
        mov ecx, [ecx + 1]
        add edx , -1
        jmp checkForFinish


popnumFromStack:
    backupRegs
    mov edx, 0
    mov dl, [itemsCounter]
    cmp edx, 0
    je popFromStackError

    add edx, -1

    mov ebx, [stack]
    mov ecx, ebx
	add ecx , edx
    add ecx , edx
	add ecx , edx
	add ecx , edx
	mov ecx , [ecx]
	add ebx , edx
	add ebx , edx
	add ebx , edx
	add ebx , edx
    mov dword [ebx] , 0

    mov eax, ecx
    add byte [itemsCounter], -1
    jmp popFromStackEnd

    popFromStackError:
    mov eax, 0
    print illegalPopMsg
    print nullTerminator
	cmp eax, 0
	jne popFromStackEnd

    popFromStackEnd:
    restoreRegs
    ret

bitwiseAnd:
    mov ebp, esp
    add dword [operationsCounter], 1

    push ebp ;
    call pop2Items
    pop ebp
    cmp eax, 0
    je andEnd

    mov ecx, eax


    backupRegs
    call createNewNode
    restoreRegs

    bitwiseAndLoop:

        mov dl, [ebx]
        mov [eax], dl
        mov dl, [ecx]
        mov dl , dl
        and [eax], dl


		jmp goToAndNextNode

	checkAndForFinish:
        cmp ebx, 0
        je andEndFree

        cmp ecx, 0
        je andEndFree

        mov edx, eax
        backupRegs
        call allocateNode
        restoreRegs

        mov [edx + 1], eax
        jmp bitwiseAndLoop

    andEndFree:

        cmp byte [debug], 1
		jne andEnd
		printDebugOutput
    andEnd:
        mov esp, ebp
        ret

    goToAndNextNode:
        mov ebx, [ebx + 1]
        mov ecx, [ecx + 1]
        jmp checkAndForFinish


summerize:
    mov ebp, esp
    add dword [operationsCounter], 1


    push ebp
    call pop2Items
    pop ebp
    cmp eax, 0
    jne continue
    mov esp, ebp
    ret

continue:
    mov ecx, eax



    backupRegs
    call createNewNode
    mov ebx, eax
    restoreRegs

    pushfd
    clc
    mov edx, 0
    summerizeLoop:

		sumUpNodes

        jmp goToNextSum

	checkforFinishSum:
        mov edx, ecx
        cmp ebx, 0
        je sumUpLast

        mov edx, ebx
        cmp ecx, 0
        je sumUpLast

        mov edx, eax
        backupRegs
        call allocateNode
        restoreRegs

        mov [edx + 1], eax
        jmp summerizeLoop

        sumUpLast:
            cmp edx, 0
            je lastCarry

            lastSumLoop:
                mov ecx, eax
                backupRegs
                call allocateNode

				restoreRegs
                mov [ecx + 1], eax

                popfd
                mov cl, [edx]
                add [eax], cl
                jnc cont
                add dword[eax], 1
                cont:
                mov edx, [edx + 1]
                pushfd
                jmp sumUpLast

            lastCarry:
                popfd
                jnc sumEndFree

                mov edx, eax
                backupRegs
                call allocateNode
				restoreRegs
                mov [edx + 1], eax
                add dword [eax], 1


    sumEndFree:
        mov ebx, [flagForN]
        cmp ebx, 1
        je sumEnd

        cmp byte [debug], 1
		jne sumEnd
		printDebugOutput

    sumEnd:
        mov esp, ebp
        ret

    goToNextSum:
        mov ebx, [ebx + 1]
        mov ecx, [ecx + 1]
        jmp checkforFinishSum
