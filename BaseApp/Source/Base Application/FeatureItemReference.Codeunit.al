#if not CLEAN19
/// <summary>
/// Replaces "Item Cross Reference" data with "Item Reference" on enabling the Item Reference feature
/// </summary>
Codeunit 5721 "Feature - Item Reference" implements "Feature Data Update"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature ItemReference got enabled by default.';
    ObsoleteTag = '19.0';

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    procedure IsDataUpdateRequired(): Boolean;
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    procedure ReviewData();
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    procedure GetTaskDescription() TaskDescription: Text;
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCountRecords(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;
}
#endif