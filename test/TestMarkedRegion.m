classdef TestMarkedRegion < matlab.unittest.TestCase
    properties
        e
    end
    
    methods(TestClassSetup)
        % Shared setup for the entire test class
        function loadClasses(~)
            addpath('../classDefinitions')
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
            MarkedRegion.setCoverageCriterion;
        end
    end
    
    methods(Test)
        % Test methods
        
        function experimentShouldFindMarkedRegions(testCase)
            regions = testCase.e.regions;
            testCase.verifyNotEmpty(regions, "Every experiment has marked region files, but they were not found. Does the experiment do a proper indexing of the region folders?")
        end
        
        function frameShouldFindMarkedRegions(testCase)
            regions = testCase.e.frame(1).regions;
            testCase.verifyNotEmpty(regions, "Frame 1 should have marked regions, but none were found")
        end

        function markedRegionsShouldBeSearchable(testCase)
            testCase.e.regions;
            query_region = testCase.e.regions([testCase.e.regions.type] == "Foot");
            testCase.verifyNotEmpty(query_region, "The experiment should be able to filter regions by their type (used 'Foot'), but none were found.")
            query_region = testCase.e.regions([testCase.e.regions.frame] == 1);
            testCase.verifyNotEmpty(query_region, "The experiment should be able to filter regions by their frame (used frame 1), but none were found.")
        end

        function markedRegionsShouldHaveUniqueIDs(testCase)
            regions = testCase.e.regions;
            ids = [regions.(regions.uniqueID)];
            testCase.verifyEqual(length(regions), length(unique(ids)), "Each marked region should have a unique ID, even if they come ")
        end

        function markedRegionShouldHaveTheseProperties(testCase)
            region = testCase.e.regions(1);
            testCase.verifySize(region.area, [1 1], "the 'area' function should retrive a scalar")
            testCase.verifySize(region.raw, [1024 1024], "The 'raw' function should retrive the image itself, with the dimensions of the image");
            testCase.verifyClass(region.raw, 'logical', "The 'raw' function should retrive the binary of the image");
            testCase.verifyEqual(size(region.plot_pixels{1}, 2), 2, "The 'plot_pixels' function should return a list of pixels in 2D space"); % should return the full area
            testCase.verifyEqual(size(region.list_pixels{1}, 2), 2, "The 'list_pixels' function should return a list of pixels in 2D space"); % should return the perimeter
            testCase.verifyGreaterThan(size(region.plot_pixels, 1), size(region.list_pixels, 1), "There should be more 'area pixels' than 'perimeter pixels' from the dimension relations")
        end

        function markedRegionShouldContainParticularCell(testCase)
            region = testCase.e.regions(2);
            particular_id = testCase.e.cells(1).cell_id;
            found_cells = region.cells;
            testCase.verifyNotEmpty(found_cells, "The marked region should contain cells, but method found none using standard method")
            testCase.verifyTrue(ismember(particular_id, [found_cells.cell_id]), "Cell $$$$ should be in the marked region, but that cell was not in the query result")
        end

        function markedRegionShouldContainParticularBond(testCase)
            region = testCase.e.regions(2);
            particular_id = testCase.e.bonds(1).bond_id;
            found_bonds = region.bonds;
            testCase.verifyNotEmpty(found_bonds, "The marked region should contain bonds, but method found none using standard method")
            testCase.verifyTrue(ismember(particular_id, [found_bonds.cell_id]), "Bond $$$$ should be in the marked region, but that bond was not in the query result")
        end

        function markedRegionCanAdjustInclusionCriterion(testCase)
            region = testCase.e.regions(2);
            particular_id = testCase.e.cells(1).cell_id;
            found_cells = region.cells;
            testCase.verifyTrue(ismember(particular_id, [found_cells.cell_id]), "Cell $$$$ should be in the marked region, but that cell was not in the query result")
            region.setCoverageCriterion(1);
            found_cells = region.cells;
            testCase.verifyFalse(ismember(particular_id, [found_cells.cell_id]), "Cell $$$$ should be is not completely in the marked region, but the query found it. Does the criterion affect the result?")
        end
    end
    
end