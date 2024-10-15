#if not CLEAN18
codeunit 11792 "Universal Single Inst. CU"
{
    SingleInstance = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Unnecessary object. This codeunit should not continue to be used.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    var
        IntrastatTemplate: Code[20];
        IntrastatBatch: Code[20];

    [Obsolete('This function is replaced by standard way of passing the recod to the called target object.', '18.0')]
    [Scope('OnPrem')]
    procedure setIntrastatJnlParam(TemplateCode: Code[20]; BatchName: Code[20])
    begin
        IntrastatTemplate := TemplateCode;
        IntrastatBatch := BatchName;
    end;

    [Obsolete('This function is replaced by standard way of passing the recod to the called target object.', '18.0')]
    [Scope('OnPrem')]
    procedure GetIntrastatJnlParam(var TemplateCode: Code[20]; var BatchName: Code[20])
    begin
        TemplateCode := IntrastatTemplate;
        BatchName := IntrastatBatch;

        IntrastatTemplate := '';
        IntrastatBatch := '';
    end;
}
#endif