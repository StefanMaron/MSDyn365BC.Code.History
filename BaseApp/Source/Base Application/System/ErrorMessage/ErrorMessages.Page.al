namespace System.Utilities;

using Microsoft.Utilities;

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
    SourceTableView = sorting("Message Type", ID)
                      order(ascending);

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
                field(Description; Rec."Message")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    DrillDown = true;
                    Enabled = EnableOpenRelatedEntity;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the message.';
                }
                field(Context; Format(Rec."Context Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context';
                    ToolTip = 'Specifies the context record.';
                    trigger OnDrillDown()
#if not CLEAN23
                    var
                        IsHandled: Boolean;
#endif
                    begin
#if not CLEAN23
                        OnDrillDownSource(Rec, Rec.FieldNo("Context Record ID"), IsHandled);
                        if not IsHandled then
#endif
                            Rec.HandleDrillDown(Rec.FieldNo("Context Record ID"));
                    end;
                }
                field("Context Field Name"; Rec."Context Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field(Source; Format(Rec."Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the record source of the error.';

                    trigger OnDrillDown()
#if not CLEAN23
                    var
                        IsHandled: Boolean;
#endif
                    begin
#if not CLEAN23
                        OnDrillDownSource(Rec, Rec.FieldNo("Record ID"), IsHandled);
                        if not IsHandled then
#endif
                            Rec.HandleDrillDown(Rec.FieldNo("Record ID"));
                    end;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies more information than the information shown in the Description field.';
                }
                field("Support Url"; Rec."Support Url")
                {
                    Caption = 'Support URL';
                    ApplicationArea = Invoicing, Basic, Suite;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL of an external web site that offers additional support.';
                }
                field(CallStack; CallStack)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Call Stack';
                    ToolTip = 'Specifies the call stack where the error occurred.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowErrorCallStack();
                    end;
                }
                field(TimeOfError; Rec."Created On")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time of Error';
                    ToolTip = 'The time of error occurence.';
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
                Caption = 'Open related record';
                Enabled = EnableOpenRelatedEntity;
                Image = View;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    OnOpenRelatedRecord(Rec, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(Rec."Record ID");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenRelatedRecord_Promoted; OpenRelatedRecord)
                {
                }
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
        CallStack := Rec.GetErrorCallStack();
    end;

    var
        PageManagement: Codeunit "Page Management";
        StyleText: Text[20];
        CallStack: Text;
        EnableOpenRelatedEntity: Boolean;

    procedure SetRecords(var TempErrorMessage: Record "Error Message" temporary)
    begin
        if TempErrorMessage.FindFirst() then;
        if TempErrorMessage.IsTemporary then
            Rec.Copy(TempErrorMessage, true)
        else
            TempErrorMessage.CopyToTemp(Rec);
    end;

    local procedure SetStyle()
    begin
        case Rec."Message Type" of
            Rec."Message Type"::Error:
                StyleText := 'Attention';
            Rec."Message Type"::Warning,
          Rec."Message Type"::Information:
                StyleText := 'None';
        end;
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := Rec."Record ID";
        EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

#if not CLEAN23
    [Obsolete('Replaced with the event OnDrillDownSource in Table 700 "Error Message"', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnDrillDownSource(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;
}

