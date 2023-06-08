classdef SimpleProfiler
    %SIMPLEPROFILER A utility class with the ability to profile certain
    %actions, and classifies them based on the duration.
    
    methods(Static)
        function time_per_obj = profile(func, array, is_bulk)
            if is_bulk
                t0 = datetime('now');
                r = func(array);
                t1 = datetime('now');
            else
                t0 = datetime('now');
                for obj = array
                    r = func(obj);
                end
                t1 = datetime('now');
            end
            time = t1 - t0;
            time_per_obj = time / length(array);
            time.Format = 's';
            time_per_obj.Format = 's';
            fprintf("total time elapsed: %s\n", time)
            if length(array) == 1
                fprintf("performance (run once): %s\n", SimpleProfiler.classify(time, true))
            else
                fprintf("time elapsed per element: %s\n", time_per_obj)
                fprintf("performance (run on array): %s\n", SimpleProfiler.classify(time_per_obj, false))
            end
        end
        
        function speed = classify(dur, run_once)
            if ~run_once
                dur = dur * 1e5;
            end
            speed = "avoid";
            if seconds(dur) < 1e4
                speed = "very slow (use sparingly)";
            end
            if seconds(dur) < 1e3
                speed = "slow (print feedback on use)";
            end
            if seconds(dur) < 1e1
                speed = "fast (good for 1D iteration)";
            end
            if seconds(dur) < 1e-1
                speed = "very fast (good for everything)";
            end
            if seconds(dur) < 1e-3
                speed = "free";
            end
        end
    end
end

