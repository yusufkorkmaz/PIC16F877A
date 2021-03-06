
	list		p=16f877A	 
	#include	<p16f877A.inc>	 
	
	__CONFIG H'3F31'  

	sagDIGIT 		EQU 0x21
	solDIGIT 		EQU 0x22 
	TUR_DEGISKEN1 	EQU 0x23
	TUR_DEGISKEN2 	EQU 0x24
	gecikme1		EQU 0x25
	gecikme2		EQU 0x26
 
	w_temp		EQU	0x7D		
	status_temp	EQU	0x7E		
	pclath_temp	EQU	0x7F					
 
	org     0x000          
  	goto    BASLA              
 
	ORG     0x004
	goto KESME

KESME
           
	movwf   w_temp            	 
	movf	STATUS,w          	 
	movwf	status_temp        
	movf	PCLATH,w	  		 
	movwf	pclath_temp	  	 
 
	BCF		INTCON,T0IF		; ?NCE TMR0 'IN BAYRA?I SIFIRLANIR KI B?R SONRAK? TMR0 KESMESI YAKALANSIN
	
	MOVLW	d'250'			; TMR0 250 DEFA TUR ATTI MI? (YANI 250msn GE?TI MI?)
	SUBWF	TUR_DEGISKEN1		
	
	BTFSS	STATUS,Z		;EGER SONUC SIFIR ISE CEVAP EVET. O ZAMAN SN KONTROLA ATLA
	GOTO	DEVAM
	
	DECFSZ	TUR_DEGISKEN2		; O ZAMAN 4 DEFA 250 TUR ATTI MI? (YANI 1sn OLDU MU?)
	GOTO	DEVAM
	
	CALL	BIR_SN_OLDU		;1sn OLUNCA CALISACAK PROGRAMI CALISTIRABILIRSIN
	
	MOVLW	d'4'			; TEKRARDAN 1SN SAYAB?LMEK ???N SIFRLANAN DEG?SKENI GUNCELLE
	MOVWF	TUR_DEGISKEN2 
	

DEVAM
	
	movf	pclath_temp,w	   
	movwf	PCLATH		  		
	movf    status_temp,w     	
	movwf	STATUS            	
	swapf   w_temp,f
	swapf   w_temp,w          	
	retfie                    

KATOT_LOOKUP  
	ADDWF	PCL,1			     
	RETLW	0x3F
	RETLW	0x06
	RETLW	0x5B
	RETLW	0x4F
	RETLW	0x66
	RETLW	0x6D
	RETLW	0x7D
	RETLW	0x07
	RETLW	0x7F
	RETLW	0x6F 

onAYARLAR

	BANKSEL	OPTION_REG	    ;OPTION_REG 'IN BULUNDUGU BANK 'A GEC
	BCF		INTCON,T0IE
	BCF		INTCON,GIE
	MOVLW	b'00000010'	    ;OPTION REG DE PSA TMR0 ICIN AYARLANDI ve PRESCALAR 1:8
	MOVWF	OPTION_REG	    ;TMR0 KESMESI I?IN 2.ADIM
	
	CLRF	TRISB		    ;HAZIR BANK 1 'DEYKEN PORTB NIN HEPSINI ?IKIS YAP 3.ADIM
	
	BANKSEL	PORTB		    ;BANK1 E GE? VE PORTB YE BASTA 0 Y?KLE
	CLRF	PORTB
	
	MOVLW	d'130'		    ;TMR0 'IN 4MHZ 'DE 1msn LIK KESME ?RETEBILMESI I?IN 
	MOVWF	TMR0		    ;125 TANE SAYMALI BU NEDENLE 130 YUKLE 4.ADIM
  
	MOVLW	d'250'		    ;1sn SAYMAK ICIN 1000 SEFER TMR0 ?ALISMALI. 
	MOVWF	TUR_DEGISKEN1	    ;BUNUN ICIN IKI DEGISKEN KULLANILIR. BIRINCISINDE 250 ?K?NC?S?NE 4 ATAYABILIRIZ
	MOVLW	d'4'		    ;4x250 =1000msn (1sn)
	MOVWF	TUR_DEGISKEN2
	
	BSF		INTCON,T0IE	    ;TMR0 DAN GELECEK KESMELER AKTIF
	BSF		INTCON,GIE	    ;T?M KESMELER AKTIF
	return

BASLA 
	
	call 	onAYARLAR
	BANKSEL ADCON1
	MOVLW	0x06		     
	MOVWF	ADCON1		    
	MOVLW	b'00111100'	
	BANKSEL TRISA    
	MOVWF	TRISA 
	BANKSEL TRISB
	CLRF 	TRISB
	BANKSEL PORTB
	CLRF 	PORTB

	CLRF 	sagDIGIT
	CLRF 	solDIGIT  
	
DONGU 
	
	call	sagYAK
	call	GECIKME
	call 	solYAK
	call	GECIKME
	goto 	DONGU
	
GECIKME 
	MOVLW 	d'100'
	MOVWF	gecikme1
DONGU1
	MOVLW 	d'100'
	MOVWF 	gecikme2
DONGU2
	DECFSZ 	gecikme2
	goto 	DONGU2
	DECFSZ	gecikme1
	goto 	DONGU1
	return
	
sagYAK

	BCF 	STATUS,Z
	
	BANKSEL PORTA
	
	MOVLW	0x02		    ; 2. D?SPLAYI AC
	MOVWF	PORTA 
	  
	MOVFW	sagDIGIT	 
	CALL	KATOT_LOOKUP 
	MOVWF	PORTB		    ; LOOK-UP DAN GELENI PORTB YE GONDER  
	    
	return 
  
solYAK
 	  
	MOVLW	0x01		    ; 1. DISPLAYI AC
	MOVWF	PORTA
 		    
	MOVFW	solDIGIT		     
	call	KATOT_LOOKUP 
	MOVWF	PORTB		    ; LOOK-UP DAN DONEN DEGERI PORTB YE GONDER
	   
	return

BIR_SN_OLDU
	
	BCF 	STATUS,Z
	INCF	sagDIGIT,F
	MOVLW 	d'10'
	SUBWF	sagDIGIT,W
	BTFSS 	STATUS,Z
	return 
	CLRF	sagDIGIT
	
	BCF 	STATUS,Z
	INCF	solDIGIT,F
	MOVLW 	d'6'
	SUBWF	solDIGIT,W
	BTFSS 	STATUS,Z
	return 
	CLRF	solDIGIT
	return

	END                     











