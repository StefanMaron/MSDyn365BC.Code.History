pageextension 3997 "Reten. Pol. Setup Lines Ext." extends "Retention Policy Setup Lines"
{
    layout
    {
        // Add changes to page layout here
        addbefore(Enabled)
        {
            field(KeepLastVersion; Rec."Keep last version")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether to prevent the last archived version of a document from expiring.';
                Enabled = IsDocumentArchiveTable;
                Editable = not RecIsLocked;
                Style = Subordinate;
                StyleExpr = RecIsLocked;
            }
        }
    }

    protected var
        IsDocumentArchiveTable: Boolean;

    var
        RecIsLocked: Boolean;

    internal procedure SetIsDocumentArchiveTable(TableId: Integer)
    begin
        IsDocumentArchiveTable := TableId in [Database::"Sales Header Archive", Database::"Purchase Header Archive"];
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RecIsLocked := Rec.IsLocked();
        SetIsDocumentArchiveTable(Rec."Table ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        RecIsLocked := false;
    end;
}