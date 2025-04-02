namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;

tableextension 904 "Asm. Whse. Pick Request" extends "Whse. Pick Request"
{
    fields
    {
        modify("Document No.")
        {
#pragma warning disable AL0603
            TableRelation = if ("Document Type" = const(Production)) "Assembly Header"."No." where(Status = field("Document Subtype"));
#pragma warning restore AL0603
        }

    }
}
