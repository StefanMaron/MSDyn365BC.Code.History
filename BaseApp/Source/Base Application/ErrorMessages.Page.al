page 700 "Error Messages"
{
    Caption = 'Error Messages';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
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
                field("Message Type"; "Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the message is an error, a warning, or information.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    DrillDown = true;
                    Enabled = EnableOpenRelatedEntity;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the message.';

                    trigger OnDrillDown()
                    begin
                        HandleDrillDown(FieldNo("Context Record ID"));
                    end;
                }
                field(Context; Format("Context Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context';
                    ToolTip = 'Specifies the context record.';
                }
                field("Context Field Name"; "Context Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field(Source; Format("Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the record source of the error.';

                    trigger OnDrillDown()
                    begin
                        HandleDrillDown(FieldNo("Record ID"));
                    end;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field("Additional Information"; "Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies more information than the information shown in the Description field.';
                }
                field("Support Url"; "Support Url")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL of an external web site that offers additional support.';
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    OnOpenRelatedRecord(Rec, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun("Record ID");
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableActions;
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle;
    end;

    var
        PageManagement: Codeunit "Page Management";
        [InDataSet]
        StyleText: Text[20];
        EnableOpenRelatedEntity: Boolean;

    procedure SetRecords(var TempErrorMessage: Record "Error Message" temporary)
    begin
        if TempErrorMessage.FindFirst then;
        if TempErrorMessage.IsTemporary then
            Copy(TempErrorMessage, true)
        else
            TempErrorMessage.CopyToTemp(Rec);
    end;

    local procedure SetStyle()
    begin
        case "Message Type" of
            "Message Type"::Error:
                StyleText := 'Attention';
            "Message Type"::Warning,
          "Message Type"::Information:
                StyleText := 'None';
        end;
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := "Record ID";
        EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

    local procedure HandleDrillDown(SourceFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        OnDrillDownSource(Rec, SourceFieldNo, IsHandled);
        if not IsHandled then
            case SourceFieldNo of
                FieldNo("Context Record ID"):
                    PageManagement.PageRunAtField("Context Record ID", "Context Field Number", false);
                FieldNo("Record ID"):
                    PageManagement.PageRunAtField("Record ID", "Field Number", false);
            end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownSource(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;
}

