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
        CashDeskNo: Code[20];

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

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure setCashDeskNo(CashDeskNo2: Code[20])
    begin
        if (CashDeskNo2 <> CashDeskNo) and (CashDeskNo2 <> '') then
            CashDeskNo := CashDeskNo2;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.0')]
    [Scope('OnPrem')]
    procedure getCashDeskNo(): Code[20]
    begin
        exit(CashDeskNo);
    end;
}

