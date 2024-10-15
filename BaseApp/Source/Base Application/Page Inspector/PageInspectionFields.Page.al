page 9632 "Page Inspection Fields"
{
    Caption = 'Page Inspection Fields';
    PageType = ListPart;
    SourceTable = "Page Info And Fields";
#if not CLEAN19
    ObsoleteState = Pending;
    ObsoleteReason = 'This page is used to generate system metadata and will be marked as non-extensible. You can keep using this page but remove any page extension referencing it.';
    ObsoleteTag = '19.0';
#else
    Extensible = false;
#endif

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                Visible = HasSourceTable;
                field("Field Info"; "Field Info")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field''s name, ID, data type, and if it is a primary key.';
                }
                field("Field Value"; "Field Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the field for the record.';
                }
                field(EmptyText; EmptyText)
                {
                    ApplicationArea = All;
                    Caption = 'EmptyText';
                    ShowCaption = false;
                    ToolTip = 'Specifies an empty field. This field is used for layout purposes.';
                }
                field(ExtensionSource; ExtensionSource)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the extension that adds the field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        // we need that to make Extension Source
        // move to the next line
        EmptyText := '';
    end;

    var
        HasSourceTable: Boolean;
        EmptyText: Text;

    [Scope('OnPrem')]
    procedure UpdatePage(FormServerHandleId: Text; FormServerBookmark: Text)
    begin
        // that performs actual data retrieval
        Reset;
        SetFilter("Current Form ID", '%1', FormServerHandleId);
        SetFilter("Current Form Bookmark", '%1', FormServerBookmark);
        // sets current record to the first one
        // so we always are in the first data block when fields are loaded
        FindFirst;

        // this will actually update the content of the page
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetFieldListVisibility(IsFieldListVisible: Boolean)
    begin
        HasSourceTable := IsFieldListVisible;
    end;
}

