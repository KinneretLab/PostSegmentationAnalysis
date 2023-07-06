classdef TestCell < matlab.unittest.TestCase
    properties
        e
    end
    
    methods(TestClassSetup)
        % Shared setup for the entire test class
        function loadClasses(~)
            addpath('../classDefinitions')
            addpath('../cellAnalysisSubfunctions')
        end
    end
    
    methods(TestMethodSetup)
        function loadExperiment(testCase)
            testCase.e = Experiment.load('example/Cells');
        end
    end

    methods(TestMethodTeardown)
        function clearExperiment(testCase)
            testCase.e = [];
            Experiment.clear;
        end
    end
    
    methods(Test)
        % Test methods
        
        function experimentShouldFindCells(testCase)
            cells = testCase.e.cells;
            testCase.verifyNotEmpty(cells, "Every experiment has cells, but they were not found. Make sure the experiment points to a valid folder.")
        end
        
        function cellShouldHaveDBonds(testCase)
            c = testCase.e.cells(1);
            testCase.verifyNotEmpty(c.dBonds, "Every cell should be composed of directed bonds, but cell 1 points to none.")
        end

        function cellDBondsShouldBeSorted(testCase)
            cells = testCase.e.cells;
            for i = 1:length(cells)
                c = testCase.e.cells(i);
                dbonds = c.dBonds;
                for idx = 1:(length(dbonds)-1)
                    testCase.verifyEqual(dbonds(idx).left_dbond_id, dbonds(idx+1).dbond_id, "The directed bonds of a cell should be sorted cyclically: each dbond points to the next. This does not happen with DBond #"+ idx+ " of cell "+i)
                end
                testCase.verifyEqual(dbonds(length(dbonds)).left_dbond_id, dbonds(1).dbond_id, "The directed bonds of a cell should be sorted cyclically: each dbond points to the next. This does not happen with DBond #"+ length(dbonds)+ " of cell "+i)
            end
        end
    end
    
end