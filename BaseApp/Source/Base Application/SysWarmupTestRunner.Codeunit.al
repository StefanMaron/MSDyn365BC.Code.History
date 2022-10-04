#if NOT CLEAN21
codeunit 130410 "Sys. Warmup Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;
    ObsoleteState = Pending;
    ObsoleteReason = 'The codeunit will be deleted';
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"Sys. Warmup Scenarios");
    end;
}
#endif