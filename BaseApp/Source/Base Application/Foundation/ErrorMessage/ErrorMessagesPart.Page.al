page 701 "Error Messages Part"
{
    Caption = 'Error Messages';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Error Message";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Message Type", ID)
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the message is an error, a warning, or information.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies error messages that occur during data processing.';
                    Visible = false;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field where the error occurred.';
                    Width = 10;
                }
                field(Description; Rec."Message")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Enabled = EnableOpenRelatedEntity;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the message.';

                    trigger OnDrillDown()
                    begin
                        if not DisableOpenRelatedEntity then
                            PageManagement.PageRun("Record ID");
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Related Record';
                Enabled = EnableOpenRelatedEntity;
                Image = View;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                begin
                    PageManagement.PageRun("Record ID");
                end;
            }
            action(ViewDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Details';
                Image = ViewDetails;
                ToolTip = 'Show more information about this error message.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"Error Messages", Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableActions();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    var
        PageManagement: Codeunit "Page Management";
        RecordIDToHighlight: RecordID;
        [InDataSet]
        StyleText: Text[20];
        EnableOpenRelatedEntity: Boolean;
        DisableOpenRelatedEntity: Boolean;

    procedure SetRecords(var TempErrorMessage: Record "Error Message" temporary)
    begin
        Reset();
        DeleteAll();

        TempErrorMessage.Reset();
        if TempErrorMessage.FindFirst() then
            Copy(TempErrorMessage, true);
    end;

    procedure SetRecordID(recordID: RecordID)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Record ID", recordID);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        SetRecords(TempErrorMessage);
        CurrPage.Update();
    end;

    procedure GetStyleOfRecord(RecordVariant: Variant; var StyleExpression: Text)
    var
        RecordRef: RecordRef;
    begin
        if not RecordVariant.IsRecord then
            exit;

        RecordRef.GetTable(RecordVariant);
        RecordIDToHighlight := RecordRef.RecordId;

        if HasErrorMessagesRelatedTo(RecordVariant) then
            StyleExpression := 'Attention'
        else
            StyleExpression := 'None';
    end;

    local procedure SetStyle()
    var
        RecID: RecordID;
    begin
        RecID := "Record ID";

        case "Message Type" of
            "Message Type"::Error:
                if RecID = RecordIDToHighlight then
                    StyleText := 'Unfavorable'
                else
                    StyleText := 'Attention';
            "Message Type"::Warning,
          "Message Type"::Information:
                if RecID = RecordIDToHighlight then
                    StyleText := 'Strong'
                else
                    StyleText := 'None';
        end;
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := "Record ID";
        if DisableOpenRelatedEntity then
            EnableOpenRelatedEntity := false
        else
            EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

    procedure DisableActions()
    begin
        DisableOpenRelatedEntity := true;
    end;
}

