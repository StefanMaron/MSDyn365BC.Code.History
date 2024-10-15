page 20301 "Tax Component Summary"
{
    PageType = ListPart;
    SourceTable = "Tax Component Summary";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'Summary';
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowAsTree = true;
                IndentationColumn = "Indentation Level";
                IndentationControls = "Component Name";
                field("Component Name"; "Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the component';
                    Style = Subordinate;
                }
                field("Component %"; "Component %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rate of the component';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the component';
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        TaxDocumentStatsMgmt.ClearBuffer();
    end;

    procedure UpdateTaxComponent(RecordIDList: List of [RecordID])
    begin
        TaxDocumentStatsMgmt.UpdateTaxComponent(RecordIDList, Rec);
    end;

    var
        TaxDocumentStatsMgmt: Codeunit "Tax Document Stats Mgmt.";
}