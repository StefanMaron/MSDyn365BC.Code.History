#if not CLEAN20
codeunit 11769 "Change Dimension Management"
{
    Permissions = TableData "Dimension Value" = rim,
                  TableData "Default Dimension" = r;
    SingleInstance = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '20.0')]
    [Scope('OnPrem')]
    procedure UpdateDimensionValue(RecRef: RecordRef; XRecRef: RecordRef; IsInsert: Boolean)
    begin
        exit;
    end;
}

#endif