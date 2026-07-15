function tests = test_model_project_inventory
tests = functiontests(localfunctions);
end

function testInventoryFindsExistingAssetsWithoutSecondaryCache(testCase)
toolkitRoot = char(java.io.File(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..')).getCanonicalPath());
addpath(genpath(fullfile(toolkitRoot, 'tools', 'common')));
addpath(genpath(fullfile(toolkitRoot, 'tools', 'model_project')));
root = tempname;
cleanup = onCleanup(@() removeFixture(root));
mkdir(fullfile(root,'matlab','unit_tests','test_harness'));
mkdir(fullfile(root,'matlab','unit_tests','test_manager'));
touch(fullfile(root,'matlab','plant.slx'));
touch(fullfile(root,'matlab','unit_tests','test_harness','plant_Harness.slx'));
touch(fullfile(root,'matlab','unit_tests','test_manager','plant_tests.mldatx'));

out = model_project_inventory(root);

verifyEqual(testCase,out.counts.models,1);
verifyEqual(testCase,out.counts.harnesses,1);
verifyEqual(testCase,out.counts.test_manager_files,1);
verifyFalse(testCase,isfolder(fullfile(root,'.satk')));
clear cleanup;
end

function touch(path)
fid=fopen(path,'w'); fclose(fid);
end

function removeFixture(root)
if isfolder(root), rmdir(root,'s'); end
end
