.data
DICT: .word FRIENDS
FRIENDS: .word GAUSS, LEIBINIZ, NEWTON, LOVELACE, BABBAGE, FARADAY, BOB, 0xFFFFFFFF
GAUSS: .word NEWTON, LEIBINIZ, BABBAGE, 0xFFFFFFFF
LEIBINIZ: .word GAUSS, 0xFFFFFFFF
NEWTON: .word GAUSS, BABBAGE, 0xFFFFFFFF
LOVELACE: .word BABBAGE, FARADAY, 0xFFFFFFFF
BABBAGE: .word GAUSS, LOVELACE, NEWTON, 0xFFFFFFFF
FARADAY: .word LOVELACE, BOB, 0xFFFFFFFF
BOB: .word FARADAY, 0xFFFFFFFF

.text
.global _start
_start:
	la s0, DICT 
	lw s0, 0(s0) # s0 = address of friends "dictionary" (really a list of lists)
	addi s1, zero, 0 # s1 = current longest chain
	addi s11, zero, -1 # S11 = -1, not replaced bbecause i'm lazy
LOOP:	lw s2, 0(s0) # Get next friend in dictionary
	beq s2, s11, DONE # If this is -1, we've reached the end of our dictionary
	add a0, zero, s2 
	addi a1, zero, 0
	jal FRIENDSHIP_IS_MAGIC # Calls subroutine with a0 = friend_to_check, a1 = 0 for no friends in seen list
	add a0, zero, s1 
	add a1, zero, a2
	jal MAX # Calls max subroutine with a0 = current max and a1 = new longest chain
	add s1, zero, a0 # Set s1 = max(s1, a2)
	addi s0, s0, 4 # Move to next person
	j LOOP
DONE:	ebreak

MAX: # a0 = max(a0, a1)
	bgt a0, a1, SUB_DONE
	add a0, zero, a1
SUB_DONE:	jr ra

FRIENDSHIP_IS_MAGIC:
# Takes in a0 as current friend to check and a1 as the size of the seen friends list in the stack.
# The seen friends list starts at sp + 20
# Returns the longest chain in a2
	add t0, zero, a0 # Save a0 into t0 -> t0 = address of next friend (since friend is actually a pointer to his friends list)
	addi t1, a1, 6 # Create new stack size: the size of seen_friends (a0) + 6 (ra, t6, t0, t1, a1, t2)
	slli t1, t1, 2 # Multiply by 4 to determine stack size in bytes
	add t6, zero, a1 # Set t6 as the current seen friends stack size
FLOOP:
	lw t2, 0(t0) # Get next friend in friend list of current friend
	beq t2, s11, FDONE # If t2 == -1, then friends list has been exhausted
	j FRIEND_CHECK # Check if our new candidate has already been seen: Return 0 if he has, 1 if he hasn't
CHECK_DONE:	beqz a6, FLOOP_NEXT # If friend already seen, don't recurse into him
	add a0, zero, t2 # Prepare recursive call: Set the candidate as the new friend
	addi a1, t6, 1 # Prepare recursive call: Set the seen friends list size to the old size + 1
	j STORE_STACK # Push valid values into stack, including the seen friends list
STORE_DONE:	jal FRIENDSHIP_IS_MAGIC # Recursive call, with a0 as new friend and a1 incremented
	j POP_STACK # Get back all values from stack
POP_DONE:	bgt a1, a2, FLOOP_NEXT # Set a1 = max(a1, a2) as the current longest friendship chain
	add a1, zero, a2 
FLOOP_NEXT:	addi t0, t0, 4 # Move to next friend in potential friends list
	j FLOOP
FDONE:	add a2, a1, zero # Set a2 return value to be a1, the longest seen_friends list found
	jr ra

FRIEND_CHECK: # Reminder: t2 is the friend we're checking for
	addi a7, sp, 20 # The seen friends list starts at sp + 20
	add a5, t6, zero # Use a5 as a temporary counter, where t6 was the size of our list
CHECK_LOOP:	beqz a5, CHECK_SUB_DONE # If a5 == 0, then done iterating the list, and the friend has not been seen y et
	lw a6, 0(a7) # a6 is a friend in our seen friends list
	beq a6, t2, CHECK_SUB_DONE # If a6 = t2, then there is a match in our seen_friends list and we know that friend has been seen (exit early)
	addi a7, a7, 4 # Move to next friend in seen friends list
	addi a5, a5, -1 # Decrement loop counter
	j CHECK_LOOP
CHECK_SUB_DONE:
	seqz a6, a5 # If a5 == 0, then the friend hasn't been seen yet. Otherwise, the friend was seen
	j CHECK_DONE

STORE_STACK:
	addi t3, sp, 20 # Save t3 as the old seen friends list to copy over
	sub sp, sp, t1 # Create space in our stack equal to t1
	sw ra, 0(sp) 
	sw t6, 4(sp)
	sw t0, 8(sp)
	sw t1, 12(sp)
	sw a1, 16(sp)
	sw t2, 20(sp) # Append t2 to our list by placing it at sp + 20
	addi t2, sp, 24 # Begin copying over our old list to here (from seen_friends_list[1:], since sp + 20 is t2)
SLOOP:
	beqz t6, SLOOP_DONE # If t6 is 0, then we're done iterating through the seen friends list
	lw t0, 0(t3) # Get old seen friend
	sw t0, 0(t2) # Place into new seen friends list
	addi t3, t3, 4 # Move to next old seen friend
	addi t2, t2, 4 # Move to vacant location in new seen friends list
	addi t6, t6, -1 # Decrement loop counter
	j SLOOP
SLOOP_DONE:
	j STORE_DONE

POP_STACK: # Pop back the stack we care about, and then reset the sp (beyond also the seen friends list)
	lw ra, 0(sp) 
	lw t6, 4(sp)
	lw t0, 8(sp)
	lw t1, 12(sp)
	lw a1, 16(sp)
	lw t2, 20(sp)
	add sp, sp, t1
	j POP_DONE