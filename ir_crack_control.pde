
#define DEBUG 1

#define IR_LED 7
#define GREEN_LED 6
#define RED_LED 5
#define YELLOW_LED 4
#define SONAR_PIN 0

#define MAX 128
#define MICRO_STEP 10

#define IDLE_PULSE 10000
#define START_PULSE 4000
#define REPEAT_PULSE 2000
#define ONE_PULSE 1500
#define ZERO_PULSE 400

unsigned long pulses[MAX];
unsigned long code = 0;
int red_led_state = 0;

void setup()
{
  pinMode(IR_LED, INPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT);
  
  digitalWrite(RED_LED, LOW);
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(YELLOW_LED, LOW);
  
  // For debug
  Serial.begin(115200);
}

void loop()
{   
  // The IR receiver output is set HIGH until a signal comes in ...
  if( digitalRead(IR_LED) == LOW)
  {
    // No command can be received while the green LED is off
    digitalWrite(GREEN_LED, LOW);
    
    //Start receiving data ...
    int count = 0; // Number of pulses
    int exit = 0;
    while(!exit)
    {
      while( digitalRead(IR_LED) == LOW )
        delayMicroseconds(MICRO_STEP);

      // Store the time when the pulse begin      
      unsigned long start = micros();

      int max_high = 0;
      while( digitalRead(IR_LED) == HIGH )
      {
        delayMicroseconds(MICRO_STEP);
        
        max_high += MICRO_STEP;
        if( max_high > IDLE_PULSE )
        {
          exit = 1;
          break;
        }
      }
        
      unsigned long duration = micros() - start;
      pulses[count++] = duration;
    }
    
    // Build code from pulses
    int repetitions = 0;    
    int bit_position = 0;
    unsigned long bit = 2147483648; // 10000000000000000000000000000000 in binary
    unsigned long new_code = 0;
    
    for(int i=0; i<count; i++)
    {
      if(pulses[i] > IDLE_PULSE)
      {
        // Ignore very long pulses
        continue;
      }
      else if(pulses[i] > START_PULSE)
      {
        // Start pulse received ... start counting bits
        new_code = 0;
        bit_position = 0;
      }
      else if(pulses[i] > REPEAT_PULSE)
      {
        // Repetition command ... no bit pulses here.
        repetitions++;
      }
      else if(pulses[i] > ONE_PULSE)
      {
        // Receives "1"
        if(DEBUG)
          Serial.print("1");
          
        new_code |= bit >> bit_position++;
      }
      else if(pulses[i] > ZERO_PULSE)
      {
        // Receives "0"
        if(DEBUG)
          Serial.print("0");
          
        bit_position++;        
      }
    }
    
    if( new_code )
    {
      // This was not a repeat command
      code = new_code;
    }
    
    // Display the code received and number of bits or, repetitions.
    if(DEBUG)
    {
      if( !new_code)
      {
        Serial.print("                                ");
      }
    
      Serial.print("     ");
      Serial.print(bit_position, DEC);
      Serial.print(" bits ");
      Serial.print(repetitions, DEC);
      Serial.print(" repetition(s) code = ");
      Serial.print(code, BIN);
      Serial.print(" (");
      Serial.print(code, DEC);
      Serial.print(")");
    
      Serial.println("");
    }
    
    
    // Flashes the yellow LED for every repeat commands
    if( repetitions > 0 )
    {
      for( int i=0; i<repetitions; i++)
      {
        digitalWrite(YELLOW_LED, HIGH);
        delay(50);
        digitalWrite(YELLOW_LED, LOW);
        delay(50);
      }
    }
    
    // POWER    279939191
    // UP       279933071
    // DOWN     279949391
    
    // Toggle red LED when power button command is received
    if(code == 279939191 && bit_position > 0) 
    {       
      red_led_state ^= 1;
      if(red_led_state)
        digitalWrite(RED_LED, HIGH);
      else
        digitalWrite(RED_LED, LOW);
    }
    
    if( code == 279933071 && bit_position > 0)
    {        
      red_led_state = 1;
      digitalWrite(RED_LED, HIGH);
    }
    
    if( code == 279949391 && bit_position > 0)
    {        
      red_led_state = 0;
      digitalWrite(RED_LED, LOW);
    }
    
    // Ready to process an other command
    digitalWrite(GREEN_LED, HIGH);
  }
}

