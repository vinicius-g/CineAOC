.data
    # "Matriz", fizemos um grande vetor, 3 sessões, 25 lugares, 75 bytes
    all_seats:      .byte 0:75  
    
    titles:         .space 60   
    
    # Variáveis de Controle
    session_count:  .word 0     
    current_base:   .word 0     
    current_ptr:    .word 0     
    
    str_main_menu:  .asciiz "\n=== CINEAOC ===\n1. Cadastrar Nova Sessao\n2. Entrar em Sessao\n3. Sair\nEscolha: "
    str_ask_title:  .asciiz "\nDigite o Titulo do Filme: "
    str_reg_ok:     .asciiz "Sessao cadastrada com sucesso!\n"
    str_limit_err:  .asciiz "\n[ERRO] Limite de 3 sessoes atingido! Impossivel criar mais.\n"
    
    str_select:     .asciiz "\n--- ESCOLHA A SESSAO ---\n"
    str_enter_id:   .asciiz "Digite o ID da sessao (0, 1 ou 2): "
    str_err_sess:   .asciiz "\n[ERRO] ID Invalido ou Sessao nao existe!\n"

    str_room_menu:  .asciiz "\n[ MENU DA SALA ]\n1. Reservar Assento\n2. Voltar ao Menu Principal\nEscolha: "
    str_ask_row:    .asciiz "\nFileira (A-E): "
    str_ask_col:    .asciiz "\nColuna  (1-5): "
    
    msg_success:    .asciiz "Reserva realizada com SUCESSO!\n"
    msg_taken:      .asciiz "[ERRO] Este lugar ja esta ocupado!\n"
    msg_error:      .asciiz "[ERRO] Coordenada invalida!\n"

    str_header:     .asciiz "\n\n=== SALA: "
    str_col_num:    .asciiz " ===\n     1   2   3   4   5\n   +-------------------+\n"
    str_row_start:  .asciiz " |"
    str_seat_free:  .asciiz "[ ] "
    str_seat_busy:  .asciiz "[X] "
    str_row_end:    .asciiz "|\n"
    str_screen:     .asciiz "   +-------------------+\n        [ TELA ]\n"
    
    str_sep:        .asciiz " - "
    newline:        .asciiz "\n"

.text
.globl main

main:
    li $v0, 4
    la $a0, str_main_menu
    syscall
    
    li $v0, 5
    syscall
    move $t0, $v0
    
    beq $t0, 1, create_session
    beq $t0, 2, list_sessions
    beq $t0, 3, exit_system
    j main

create_session:
    lw $t0, session_count
    bge $t0, 3, show_limit_error # Validação de limite de sessões
    
    li $v0, 4
    la $a0, str_ask_title
    syscall
    
    la $t1, titles
    mul $t2, $t0, 20
    add $a0, $t1, $t2  
    li $a1, 20          
    li $v0, 8          
    syscall
    
    move $a0, $a0       
    jal remove_newline
    
    lw $t0, session_count
    addi $t0, $t0, 1
    sw $t0, session_count
    
    li $v0, 4
    la $a0, str_reg_ok
    syscall
    j main

show_limit_error:
    li $v0, 4
    la $a0, str_limit_err
    syscall
    j main

list_sessions:
    li $v0, 4
    la $a0, str_select
    syscall
    
    lw $t0, session_count
    li $t1, 0   # i = 0
    
    beqz $t0, invalid_session 

list_loop:
    bge $t1, $t0, list_end  # i >= contador
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, str_sep
    syscall
    
    la $t2, titles
    mul $t3, $t1, 20
    add $a0, $t2, $t3
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t1, $t1, 1
    j list_loop

list_end:
    li $v0, 4
    la $a0, str_enter_id
    syscall
    li $v0, 5
    syscall
    move $t0, $v0   
    
    lw $t1, session_count
    bltz $t0, invalid_session
    bge $t0, $t1, invalid_session
    
    la $t2, all_seats
    mul $t3, $t0, 25   
    add $s7, $t2, $t3   
    
    sw $s7, current_ptr 
    sw $t0, current_base 
    
    j room_menu

invalid_session:
    li $v0, 4
    la $a0, str_err_sess
    syscall
    j main

room_menu:
    jal print_map
    
    li $v0, 4
    la $a0, str_room_menu
    syscall
    
    li $v0, 5
    syscall
    move $t0, $v0
    
    beq $t0, 1, do_booking
    beq $t0, 2, main      
    j room_menu

do_booking:
    li $v0, 4
    la $a0, str_ask_row
    syscall
    li $v0, 12    
    syscall
    move $t0, $v0   
    
    li $v0, 4
    la $a0, str_ask_col
    syscall
    li $v0, 5       
    syscall
    move $t1, $v0   
    
    bge $t0, 97, make_upper
    j check_upper
make_upper: 
    sub $t0, $t0, 32
check_upper:
    sub $t0, $t0, 65 
    
    bltz $t0, book_err
    bgt $t0, 4, book_err
    
    addi $t1, $t1, -1
    bltz $t1, book_err
    bgt $t1, 4, book_err
    
    mul $t2, $t0, 5
    add $t2, $t2, $t1
    
    add $t3, $s7, $t2
    
    lb $t4, 0($t3)
    bnez $t4, book_taken 
    
    li $t5, 1
    sb $t5, 0($t3)
    
    li $v0, 4
    la $a0, msg_success
    syscall
    j room_menu

book_err:
    li $v0, 4
    la $a0, msg_error
    syscall
    j room_menu

book_taken:
    li $v0, 4
    la $a0, msg_taken
    syscall
    j room_menu

print_map:
    li $v0, 4
    la $a0, str_header
    syscall
    
    lw $t0, current_base
    la $t1, titles
    mul $t0, $t0, 20
    add $a0, $t1, $t0
    li $v0, 4
    syscall
    
    li $v0, 4
    la $a0, str_col_num
    syscall
    
    li $t0, 0      
    move $s1, $s7   

map_row_loop:
    bge $t0, 5, map_end
    
    addi $a0, $t0, 65
    li $v0, 11
    syscall
    
    li $v0, 4
    la $a0, str_row_start
    syscall
    
    li $t1, 0   

map_col_loop:
    bge $t1, 5, map_row_end
    
    lb $t3, 0($s1)   
    addi $s1, $s1, 1
    
    beqz $t3, pr_free
    
    li $v0, 4
    la $a0, str_seat_busy
    syscall
    j map_nxt

pr_free:
    li $v0, 4
    la $a0, str_seat_free
    syscall

map_nxt:
    addi $t1, $t1, 1
    j map_col_loop

map_row_end:
    li $v0, 4
    la $a0, str_row_end
    syscall
    
    addi $t0, $t0, 1
    j map_row_loop

map_end:
    li $v0, 4
    la $a0, str_screen
    syscall
    jr $ra

remove_newline:
    move $t0, $a0
    
rn_loop:
    lb $t1, 0($t0)
    beqz $t1, rn_end
    beq $t1, 10, rn_fix
    addi $t0, $t0, 1
    j rn_loop
rn_fix:
    sb $zero, 0($t0)
    
rn_end:
    jr $ra

exit_system:
    li $v0, 10
    syscall