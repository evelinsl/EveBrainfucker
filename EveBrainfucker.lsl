///
/// Evelins Brainfuck Interpreter
/// Made by Evelin ❤
///
/// Check out the Github page for documentation:
/// https://github.com/evelinsl/EveBrainfucker
///

// The program to run...

string program = "
+++++ +++++             initialize counter (cell #0) to 10
[                       use loop to set 70/100/30/10
    > +++++ ++              add  7 to cell #1
    > +++++ +++++           add 10 to cell #2
    > +++                   add  3 to cell #3
    > +                     add  1 to cell #4
<<<< -                  decrement counter (cell #0)
]
> ++ .                  print 'H'
> + .                   print 'e'
+++++ ++ .              print 'l'
.                       print 'l'
+++ .                   print 'o'
> ++ .                  print ' '
<< +++++ +++++ +++++ .  print 'W'
> .                     print 'o'
+++ .                   print 'r'
----- - .               print 'l'
----- --- .             print 'd'
> + .                   print '!'";

string outputableChars = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

list whileStack = [];
list whileCounter = [];
integer skipLoop = -1;
integer skipInstruction = FALSE;

list data = [0];
string output = "";

integer pointer = 0;

string error = "";
string ran = "";


///
/// Free up memory after finishing the program
///
cleanup()
{
    whileStack = [];
    whileCounter = [];
    skipLoop = -1;
    data = [0];
    output = "";
    pointer = 0;
    error = "";
    ran = "";
}


///
/// "Executes" the brainfuck program by
/// looping the instructions.
/// 
execute()
{
    integer length = llStringLength(program);
    integer index = 0;
    integer jumpTo = -1;
    integer instructionRan = 0;

    @instructionLoop;

    while(index < length)
    {
        instructionRan++;
        string instruction = llGetSubString(program, index, index);
        
        if(llSubStringIndex("[]+-<>.", instruction) == -1)
        {
            index++;
            jump instructionLoop;
        }
        
        ran = ran + instruction;
      
        if(instruction == "[")
            beginWhile(index);      
         else if(instruction == "]")
            jumpTo = endWhile(index);    
        
        if(skipInstruction == FALSE)
        {         
            if(instruction == "+")
                incrementData();
            else if(instruction == "-")
                decrementData();    
            else if(instruction == ">")
                incrementPointer();
            else if(instruction == "<")
                decrementPointer();  
            else if(instruction == ".")
                outputValue(); 
        }
        
        // Stop execution if we encountered something wrong 
           
        if(error != "")
        {
            llSay(0, "Encountered error: " + error);
            return;
        }     
        
        // Do we need to jump to a certain position?
        
        if(jumpTo > -1)
        {
            index = jumpTo;
            jumpTo = -1;
        } else
            index++;
            
        // Just some safety for runaway scripts
        
        if(instructionRan > 6000)
        {
            llSay(0, "ABORT Script. " + (string)instructionRan + " instructions processed.");
            return;
        }            
    }
}


dumpProgramState()
{
    llSay(0, "Memory: " + llList2CSV(data));
    llSay(0, "Pointer: " + (string)pointer);
    llSay(0, "SkipInstruction: " + (string)skipInstruction + " - SkipLoop: " + (string)skipLoop);
    llSay(0, "Output: " + output); 
    llSay(0, "Ran: " + ran); 
}


///
/// Start of a loop. This loop will only run
/// as long the loopcounter is non zero. 
///
beginWhile(integer position)
{
    if(skipInstruction == TRUE)
    {
        skipLoop++;
        if(skipLoop > -1)
            return; // Continue skipping
    }
    
    integer value = llList2Integer(data, pointer);
    
    // Entered a while loop, check if the value is higher than 0
    // if so, we execute the next instruction.
    // Or else we skip all instructions and jump to the related ]
    // while ignoring all intermediate instructions.
    
    if(value > 0)
    {
        whileCounter += [pointer];
        whileStack += [position + 1];
        return;
    } 
     
    // End the loop and walk to our related ] instruction,
    // ignoring all intermediate instructions.
    
    skipInstruction = TRUE;
    skipLoop++;
}


///
/// Process the end a loop. If the loopcounter is zero,
/// we abort the loop and continue with the instruction after it.
/// Our while loop is kinda a while-do-while loop...
///
integer endWhile(integer position)
{
    if(skipInstruction == TRUE)
    {
        // If we are skipping an outer while, we exit
        
        skipLoop--;
        if(skipLoop >= 0)
            return -1;
    }
    
    // Test the loop counter
    
    integer value = llList2Integer(data, llList2Integer(whileCounter, -1));
    
    if(value == 0) 
    {
        // The value is zero so lets exit this loop.
        
        whileStack = llDeleteSubList(whileStack, -1, -1);
        return -1;
    }
    
    // Pop back to our starting point 
    // to run the loop again.
    
    integer beginning = llList2Integer(whileStack, -1);
    
    if(beginning == position)
    {
        // If this loop is empty, then try it abort it right away
        // or bad things will happen.

        whileStack = llDeleteSubList(whileStack, -1, -1);
        return -1;
    } 
    
    return beginning;
}


/// 
/// "Outputs" a value at the current pointer position
/// to our output string. But only if the byte can be
/// converted to an ascii char. 
///
outputValue()
{
    integer value = llList2Integer(data, pointer);

    if(value < 32 || value > 32 + llStringLength(outputableChars))
        return;
    
    output += llGetSubString(outputableChars, value - 32, value - 32);
}


///
/// Moves the pointer up one position
///
incrementPointer()
{
    alloc(pointer + 1);
    pointer++;
}


///
/// Moves the pointer 1 position back
///
decrementPointer()
{
    pointer--;
    
    if(pointer < 0)
    {
        error = "Pointer is out of bounds (0)";
        return;
    }
}


///
/// Allocates a new byte at the given pointer position.
/// Every byte between the last entry and the new entry
/// will be initialized too.
///
alloc(integer position)
{
    if(position < 0)
    {
        error = "Pointer would go out of bounds (0)";
        return;
    }
    
    if(position > 512)
    {
        error = "Pointer would go out of bounds (memory limit)";
        return;
    }
    
    integer add = -(llGetListLength(data) - pointer);
    for(; add > 0; add--)
        data += [0];
}


///
/// Increments the current value with 1
///
incrementData()
{
    integer newValue = llList2Integer(data, pointer) + 1;
    
    if(newValue > 255)
        newValue = 0;
        
    data = llListReplaceList(data, [newValue], pointer, pointer);    
}


///
/// Decrements the current value with 1
///
decrementData()
{
    integer newValue = llList2Integer(data, pointer) - 1;
    
    if(newValue < 0)
        newValue = 255;
        
    data = llListReplaceList(data, [newValue], pointer, pointer);     
}


default
{
    state_entry()
    {
        execute();
        dumpProgramState();
        cleanup();
    }

    touch_start(integer total_number)
    {
        llSay(0, "Evelin's Brainfuck interpreter ( https://en.wikipedia.org/wiki/Brainfuck )");
        llSay(0, "Starting program...");
        
        execute();
        dumpProgramState();
        cleanup();
    }
}
