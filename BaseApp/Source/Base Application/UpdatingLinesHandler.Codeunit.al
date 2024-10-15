#if not CLEAN18
codeunit 11772 "Updating Lines Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnUpdateTransLines', '', false, false)]
    local procedure UpdateTransLinesOnUpdateTransLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; FieldID: Integer)
    begin
        with TransferHeader do
            case FieldID of
                FieldNo("Transfer-from Code"):
                    begin
                        TransferLine.Validate("Gen. Bus. Post. Group Ship", "Gen. Bus. Post. Group Ship");
                        TransferLine.Validate("Gen. Bus. Post. Group Receive", "Gen. Bus. Post. Group Receive");
                    end;
                FieldNo("Transfer-to Code"):
                    begin
                        TransferLine.Validate("Gen. Bus. Post. Group Ship", "Gen. Bus. Post. Group Ship");
                        TransferLine.Validate("Gen. Bus. Post. Group Receive", "Gen. Bus. Post. Group Receive");
                    end;
                FieldNo("Gen. Bus. Post. Group Ship"):
                    TransferLine.Validate("Gen. Bus. Post. Group Ship", "Gen. Bus. Post. Group Ship");
                FieldNo("Gen. Bus. Post. Group Receive"):
                    TransferLine.Validate("Gen. Bus. Post. Group Receive", "Gen. Bus. Post. Group Receive");
            end;
    end;
}
#endif
