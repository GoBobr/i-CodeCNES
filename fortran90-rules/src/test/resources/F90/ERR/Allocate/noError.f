!
! Ce programme effectue l'allocation dynamique de deux tableaux.
! Lees deux tableaux sont initialises avec des données qui sont saisies au clavier .
! Une fois, le tableau rempli, on appelle 3 fonctions intrinsèques :
! . MINVAL : qui permet d'extraire la valeur minimale d'un tableau
! . MAXVAL : qui permet d'extraire la valeur maximale d'un tableau
! . SUM : qui permet d'effectuer le calcul de la somme de tous les elements d'un tableau
!
PROGRAM ESSAI

      IMPLICIT NONE 

      INTEGER, parameter :: n1 = 20
      INTEGER, parameter :: n2 = 10
      INTEGER            :: iom

      REAL               :: plus_petit
      REAL               :: plus_grand
      REAL               :: Somme_A
      REAL               :: Somme_B

      REAL, DIMENSION(:), ALLOCATABLE :: A 
      REAL, DIMENSION(:), ALLOCATABLE :: B 

! --- Allocation du tableau A
      allocate(A(n1), STAT = iom)
      if (iom > 0) then
         call f_Syslog('Allocation du tableau A echouee')
         stop
      end if

! --- Allocation du tableau B
      allocate(B(n2))
      if ( .NOT. allocated(B)) then
         call f_Syslog('Allocation du tableau B echouee')
         stop
      end if

! --- On alimente le contenu des 2 tableaux avec des valeurs saisies au clavier 
      write(*, '(A,I2,A)', ADVANCE = "NO") "Saisir les valeurs (", n1, ") de A : "
      read(*,*) A
      write(*, '(A,I2,A)', ADVANCE = "NO") "Saisir les valeurs (", n2, ") de B : "
      read(*,*) B

! Appel de la fonction intrinseque MINVAL afin de determiner la valeur minimale des elements du tableau
      plus_petit = MINVAL(A)
      write(*,'(A,F8.2)') "Plus petite valeur du tableau A", Plus_Petit

! Appel de la fonction intrinseque MAXVAL afin de determiner la valeur maximale des elements du tableau
      plus_grand = MAXVAL(B)
      write(*,'(A,F8.2)') "Plus grande valeur du tableau B", Plus_Grand

! Appel fonction intrinseque SUM pour calcul de la somme des elements des tableaux A puis B
      Somme_A = SUM(A)
      Somme_B = SUM(B)

! Impression sur sortie standard du resultat obtenu
      write(*,'(A,F8.2)') "La somme des elements du tableau A est ", Somme_A
      write(*,'(A,F8.2)') "La somme des elements du tableau B est ", Somme_B

! Desallouer la memoire associee aux tableaux 
      if (allocated(A)) then 
         deallocate(A, stat=iom)
         if (iom > 0) then
            call f_Syslog('Desallocation du tableau A echouee')
         endif 
      else 
            call f_Syslog('Desallocation du tableau A deja effectuee')
      endif 
      if (allocated(B)) then 
         deallocate(B, stat=iom)
         if (iom > 0) then
            call f_Syslog('Desallocation du tableau B echouee')
         endif 
      else 
            call f_Syslog('Desallocation du tableau B deja effectuee')
      endif 

END PROGRAM ESSAI

! Wrapper subroutine that internally uses ALLOCATE with STAT= — should NOT trigger
! the rule at the CALL site (the word "allocate" in "lintran_allocate" must not match)
SUBROUTINE lintran_allocate(n, arr, error_code)
      INTEGER, INTENT(IN) :: n
      REAL, DIMENSION(:), ALLOCATABLE, INTENT(INOUT) :: arr
      INTEGER, INTENT(OUT) :: error_code
      ALLOCATE(arr(n), STAT=error_code)
      IF (error_code /= 0) RETURN
END SUBROUTINE lintran_allocate

SUBROUTINE test_wrapper_call()
      REAL, DIMENSION(:), ALLOCATABLE :: data_arr
      INTEGER :: err
      ! This CALL contains "allocate" in the subroutine name — must NOT trigger
      CALL lintran_allocate(100, data_arr, err)
      IF (err /= 0) RETURN
      ! Multi-line ALLOCATE with continuation — STAT= on next line
      ALLOCATE(data_arr(200), &
               STAT=err)
      IF (err /= 0) RETURN
      DEALLOCATE(data_arr, STAT=err)
      IF (err /= 0) RETURN
END SUBROUTINE test_wrapper_call

! Test: ALLOCATE inside IF block with status check several lines later
program alloc_if_test
  implicit none
  integer :: iostat
  double precision, dimension(:), allocatable :: arr1, arr2
  iostat = 0
  if (iostat == 0) then
    allocate(arr1(100), stat=iostat)
  end if
  if (iostat == 0) then
    allocate(arr2(200), stat=iostat)
  end if
  if (iostat /= 0) then
    print *, 'Allocation error'
  end if
  deallocate(arr1, stat=iostat)
  if (iostat /= 0) then
    print *, 'Deallocation error arr1'
  end if
  deallocate(arr2, stat=iostat)
  if (iostat /= 0) then
    print *, 'Deallocation error arr2'
  end if
end program alloc_if_test
