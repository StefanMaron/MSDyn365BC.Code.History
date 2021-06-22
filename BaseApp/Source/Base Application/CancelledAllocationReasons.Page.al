page 6002 "Cancelled Allocation Reasons"
{
    Caption = 'Canceled Allocation Reasons';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to cancel the allocation?';
    LinksAllowed = false;
    ModifyAllowed = true;
    PageType = ConfirmationDialog;
    SourceTable = "Service Order Allocation";

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the type of the document (Order or Quote) from which the allocation entry was created.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service order associated with this entry.';
                }
                field("Allocation Date"; "Allocation Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the resource allocation should start.';
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the resource allocated to the service task in this entry.';
                }
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service item line linked to this entry.';
                }
                field("Allocated Hours"; "Allocated Hours")
                {
                    ApplicationArea = Service;
                    DecimalPlaces = 0 : 0;
                    Editable = false;
                    ToolTip = 'Specifies the hours allocated to the resource or resource group for the service task in this entry.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time when you want the allocation to start.';
                }
                field("Finishing Time"; "Finishing Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time when you want the allocation to finish.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a description for the service order allocation.';
                }
            }
            field(ServPriority; ServPriority)
            {
                ApplicationArea = Service;
                Caption = 'Priority';
                OptionCaption = 'Low,Medium,High';
            }
            field(ReasonCode; ReasonCode)
            {
                ApplicationArea = Service;
                Caption = 'Reason Code';
                TableRelation = "Reason Code";
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ServHeader.Get("Document Type", "Document No.");
        if not ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then
            ServPriority := ServHeader.Priority
        else
            ServPriority := ServItemLine.Priority;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ReasonCode: Code[10];
        ServPriority: Option Low,Medium,High;

    procedure ReturnReasonCode(): Code[10]
    begin
        exit(ReasonCode);
    end;

    procedure ReturnPriority(): Integer
    begin
        exit(ServPriority);
    end;
}

