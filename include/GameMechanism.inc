CheckIntersection PROTO :WORD, :WORD, 
                        :PTR BLOCK, :DWORD, 
                        :PTR OBSTACLE, :DWORD
INVOKE CheckSupported, ax, bx, ADDR snake, snakeLen, ADDR obstacles, obstacleLen, ADDR apples, appleLen, boxes, boxLen, goal
CheckSupported PROTO :WORD, :WORD,
                     :PTR BLOCK, :DWORD
                     :PTR OBSTACLE, :DWORD
                     :PTR APPLE, :DWORD
                     :PTR COORD, :DWORD
                     :COORD 
