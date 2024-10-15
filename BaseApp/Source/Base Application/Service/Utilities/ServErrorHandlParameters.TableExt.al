namespace Microsoft.Utilities;

using Microsoft.Service.Document;

tableextension 6476 "Serv. Error Handl. Parameters" extends "Error Handling Parameters"
{
    fields
    {
        field(16; "Service Document Type"; Enum "Service Document Type")
        {
            DataClassification = SystemMetadata;
        }
    }
}