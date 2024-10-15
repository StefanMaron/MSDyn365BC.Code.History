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
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the posted credit memo number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer to whom you shipped the service on the credit memo.';
                }
                field("Posting Date"; Rec."Posting Date")
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
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Cr. Memo Type"; Rec."Cr. Memo Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Credit Memo Type.';
                    trigger OnValidate()
                    begin
                        SIIFirstSummaryDocNo := '';
                        SIILastSummaryDocNo := '';
                    end;
                }
                field("Issued By Third Party"; "Issued By Third Party")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the credit memo was issued by a third party.';
                }
                field("SII First Summary Doc. No."; SIIFirstSummaryDocNo)
                {
                    Caption = 'First Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        SetSIIFirstSummaryDocNo(SIIFirstSummaryDocNo);
                    end;
                }
                field("SII Last Summary Doc. No."; SIILastSummaryDocNo)
                {
                    Caption = 'Last Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        SetSIILastSummaryDocNo(SIILastSummaryDocNo);
                    end;
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

    trigger OnAfterGetRecord()
    begin
        SIIFirstSummaryDocNo := Copystr(GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := Copystr(GetSIILastSummaryDocNo(), 1, 35);
    end;

    var
        xServiceCrMemoHeader: Record "Service Cr.Memo Header";
        OperationDescription: Text[500];
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          ("Operation Description" <> xServiceCrMemoHeader."Operation Description") or
          ("Operation Description 2" <> xServiceCrMemoHeader."Operation Description 2") or
          ("Special Scheme Code" <> xServiceCrMemoHeader."Special Scheme Code") or
          ("Cr. Memo Type" <> xServiceCrMemoHeader."Cr. Memo Type") or
          ("Issued By Third Party" <> xServiceCrMemoHeader."Issued By Third Party") OR
          (GetSIIFirstSummaryDocNo() <> xServiceCrMemoHeader.GetSIIFirstSummaryDocNo()) or
          (GetSIILastSummaryDocNo() <> xServiceCrMemoHeader.GetSIILastSummaryDocNo());

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

