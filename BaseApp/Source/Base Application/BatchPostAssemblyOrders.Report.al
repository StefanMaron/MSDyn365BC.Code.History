report 900 "Batch Post Assembly Orders"
{
    Caption = 'Batch Post Assembly Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Assembly Header"; "Assembly Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            var
                BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
                BatchPostParameterTypes: Codeunit "Batch Post Parameter Types";
                RecRef: RecordRef;
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);

                BatchProcessingMgt.SetProcessingCodeunit(CODEUNIT::"Assembly-Post");
                BatchProcessingMgt.AddParameter(BatchPostParameterTypes.ReplacePostingDate, ReplacePostingDate);
                BatchProcessingMgt.AddParameter(BatchPostParameterTypes.PostingDate, PostingDateReq);

                RecRef.GetTable("Assembly Header");
                BatchProcessingMgt.BatchProcess(RecRef);
                RecRef.SetTable("Assembly Header");

                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the document date or the posting date when you post. ';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the orders with the date that is entered in the Posting Date field.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ReplacePostingDate := false;
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Enter the posting date.';
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;

    procedure InitializeRequest(NewPostingDateReq: Date; NewReplacePostingDate: Boolean)
    begin
        PostingDateReq := NewPostingDateReq;
        ReplacePostingDate := NewReplacePostingDate;
    end;
}

