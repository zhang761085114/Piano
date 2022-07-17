.586
.model flat,stdcall
option casemap:none

   include windows.inc
   include user32.inc
   include kernel32.inc
   include test.inc
   include msvcrt.inc
   
   includelib user32.lib
   includelib kernel32.lib
   includelib msvcrt.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


.data
   ClassName db "MainWinClass",0
   AppName  db "Main Window",0
   g_szDll db "piano_dll.dll",0
   g_szPlay db "fun_playOneSound",0
   g_szCreate db "fun_Create", 0
   g_pfnCreate dd 0
   g_pfnPlay dd 0
   g_drawtext db ".", 0
   g_deletetext db " ", 0
   g_helptool db FALSE
   
   g_filenamefmt db "sound%c.txt", 0
   g_filename db 128 dup(0)
   g_ptrfile dd 0
   g_openmode db "r", 0
   g_filetext db 1000 dup(0)
   g_num dd 0
   g_hFile dd 0
   

.data?
   hInstance HINSTANCE ?
   CommandLine LPSTR ?

.code


; ---------------------------------------------------------------------------


start:
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	
	invoke GetCommandLine
	mov    CommandLine,eax
	
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	LOCAL hDll:HANDLE
	
	invoke LoadLibrary, offset g_szDll
	mov hDll, eax
	
	invoke GetProcAddress,eax, offset g_szPlay
	mov g_pfnPlay, eax
	invoke GetProcAddress, hDll, offset g_szCreate
	mov g_pfnCreate, eax
	
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,NULL
	push  hInstance
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_BTNFACE+1
	mov   wc.lpszMenuName,NULL
	mov   wc.lpszClassName,OFFSET ClassName
	
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax
	
	invoke RegisterClassEx, addr wc
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax
	
	invoke ShowWindow, hwnd,SW_SHOWNORMAL
	invoke UpdateWindow, hwnd
	
	.WHILE TRUE
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	
	mov     eax,msg.wParam
	ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	 LOCAL hDc:HDC
	 LOCAL hInst:HINSTANCE
	 LOCAL rcCustomClient:RECT
	 LOCAL dwReaded:DWORD
	
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.ELSEIF uMsg==WM_CREATE
	    push hWnd
	    call g_pfnCreate
	    add esp, 4
	    
	    
    .elseif uMsg == WM_KEYDOWN
        invoke GetAsyncKeyState, VK_LCONTROL
        .if eax==0
            .if g_helptool==FALSE
                push wParam
                call g_pfnPlay
                add esp, 4
                
            .else
                xor ebx, ebx
                mov ecx, [g_num]
                mov bl, [g_filetext+ecx]
                
                inc ecx
                mov [g_num], ecx
                
                push ebx
                call g_pfnPlay
                add esp, 4
                
                
            .endif
            
            
            
        .else
            .if wParam=='J'
                
                mov g_helptool, TRUE
                
                ;获取窗口DC
                invoke GetDC, hWnd
                mov hDc, eax
            
                ;获取客户区矩形
                invoke GetClientRect, hWnd, addr rcCustomClient
            
                ;画点
                invoke DrawText, hDc, offset g_drawtext, 1, addr rcCustomClient, DT_RIGHT or DT_TOP or DT_SINGLELINE
                
                ;释放DC
                invoke ReleaseDC, hDc, hWnd
            
            .elseif wParam=='K'
            
                mov g_helptool, FALSE
                ;获取窗口DC
                invoke GetDC, hWnd
                mov hDc, eax
            
                ;获取客户区矩形
                invoke GetClientRect, hWnd, addr rcCustomClient
            
                ;去掉点
                invoke DrawText, hDc, offset g_deletetext, 1, addr rcCustomClient, DT_RIGHT or DT_TOP or DT_SINGLELINE
                
                ;释放DC
                invoke ReleaseDC, hDc, hWnd
            
            .else
                .if g_helptool==TRUE && wParam >= '1' && wParam <= '9'
                
                    invoke wsprintf, offset g_filename, offset g_filenamefmt, wParam
                
                    invoke CreateFile, offset g_filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                    mov g_hFile, eax
                    invoke ReadFile, g_hFile, offset g_filetext, 1000, addr dwReaded, NULL
 
                    invoke CloseHandle, g_hFile
                    
                    xor ecx, ecx
                    mov [g_num], ecx
                .endif
            .endif
        .endif
        
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
	
	xor eax,eax
	ret
WndProc endp


end start
