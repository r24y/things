/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
[0-9]+[:][0-9]+\s?[AaPp][Mm]?\b      return 'TIME_OF_DAY'
[0-9]+[:][0-9]+\b     return 'DURATION'
[0-9]+("."[0-9]+)?\b  return 'NUMBER'
"*"                   return '*'
"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
"^"                   return '^'
"("                   return '('
")"                   return ')'
[Nn][Oo][Ww]          return 'NOW'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}
    | time_of_day EOF
        { $1 = Math.floor($1/1e3);
          var seconds = $1 % 60;
          $1 = Math.floor($1/60);
          var minutes = $1 % 60;
          $1 = Math.floor($1/60);
          var hours = $1;
          function pad(n){return n<10?'0'+n:n}
          var ap = hours < 12 ? 'am' : 'pm';
          hours %= 12;
          if(hours === 0) hours = 12;
          return (hours)+':'+pad(minutes)+':'+pad(seconds)+ap; }
    | duration EOF
        { $1 = Math.floor($1/1e3);
          var seconds = $1 % 60;
          $1 = Math.floor($1/60);
          var minutes = $1 % 60;
          $1 = Math.floor($1/60);
          var hours = $1;
          function pad(n){return n<10?'0'+n:n}
          return (hours)+':'+pad(minutes)+':'+pad(seconds); }
    ;

time_of_day
    : TIME_OF_DAY
        { var re = /([0-9]+):([0-9]+)\s?([AaPp][Mm]?)/;
          var m = $1.match(re);
          var offset = (/p/i).test(m[3]) ? 12*60*60e3 : 0;
          $$ = (Number(m[1])*60 + Number(m[2]))*60e3 + offset;
        }
    | time_of_day '+' duration
        { $$ = $1 + $3;}
    | duration '+' time_of_day
        { $$ = $1 + $3;}
    | time_of_day '-' duration
        { $$ = $1 - $3;}
    | '(' time_of_day ')'
        {$$ = $2;}
    | NOW
        { var d = new Date(), e = new Date(d);
          $$ = e - d.setHours(0,0,0,0);
        }
    ;

duration
    : DURATION
        { var re = /([0-9]+):([0-9]+)/;
          var m = $1.match(re);
          $$ = (Number(m[1])*60 + Number(m[2]))*60e3;
        }
    | time_of_day '-' time_of_day
        {$$ = $1 - $3;}
    | duration '+' duration
        {$$ = $1 + $3;}
    | duration '-' duration
        {$$ = $1 - $3;}
    | duration '*' e
        {$$ = $1 * $3;}
    | e '*' duration
        {$$ = $1 * $3;}
    | duration '/' e
        {$$ = $1 / $3;}
    | '(' duration ')'
        {$$ = $2;}
    ;
e
    : e '+' e
        {$$ = $1+$3;}
    | e '-' e
        {$$ = $1-$3;}
    | e '*' e
        {$$ = $1*$3;}
    | e '/' e
        {$$ = $1/$3;}
    | e '^' e
        {$$ = Math.pow($1, $3);}
    | duration '/' duration
        {$$ = $1 / $3;}
    | '-' e %prec UMINUS
        {$$ = -$2;}
    | '(' e ')'
        {$$ = $2;}
    | NUMBER
        {$$ = Number(yytext);}
    | E
        {$$ = Math.E;}
    | PI
        {$$ = Math.PI;}
    ;
