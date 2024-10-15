page 10769 "Posted Serv. Cr. Memo - Update"
{
    Caption = 'Posted Service Credit Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Cr.Memo Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the posted credit memo number.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer to whom you shipped the service on the credit memo.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    Editable = true;
                    MultiLine = true;
                    ToolTip = 'Specifies the Operation Description.';

                    trigger OnValidate()
                    var
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIManagement.SplitOperationDescription(OperationDescription, "Operation Description", "Operation Description 2");
                        Validate("Operation Description");
                        Validate("Operation Description 2");
                    end;
                }
                field("Special Scheme Code"; "Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Cr. Memo Type"; "Cr. Memo Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Credit Memo Type.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        xServiceCrMemoHeader := Rec;
        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then
            if RecordChanged() then
                Codeunit.Run(Codeunit::"Service Cr. Memo Header - Edit", Rec);
    end;

    var
        xServiceCrMemoHeader: Record "Service Cr.Memo Header";
        OperationDescription: Text[500];

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          ("Operation Description" <> xServiceCrMemoHeader."Operation Description") or
          ("Operation Description 2" <> xServiceCrMemoHeader."Operation Description 2") or
          ("Special Scheme Code" <> xServiceCrMemoHeader."Special Scheme Code") or
          ("Cr. Memo Type" <> xServiceCrMemoHeader."Cr. Memo Type");

        OnAfterRecordIsChanged(Rec, xServiceCrMemoHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        Rec := ServiceCrMemoHeader;
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; xServiceCrMemoHeader: Record "Service Cr.Memo Header"; var RecordIsChanged: Boolean)
    begin
    end;
}

