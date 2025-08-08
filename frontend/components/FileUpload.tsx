'use client';

import { useState, useCallback } from 'react';
import { Upload, X, FileText, Image, AlertCircle, CheckCircle } from 'lucide-react';

interface FileUploadProps {
  patientId: string;
  patientName: string;
  onUploadComplete?: (files: UploadedFile[]) => void;
  maxFiles?: number;
  allowedTypes?: string[];
  maxSizeBytes?: number;
}

interface UploadedFile {
  file_id: string;
  file_name: string;
  file_size: number;
  s3_key: string;
  category: string;
  uploaded_at: string;
  message: string;
}

interface UploadingFile {
  file: File;
  progress: number;
  error?: string;
  success?: boolean;
}

const CATEGORY_LABELS = {
  lab_results: 'Lab Results',
  insurance: 'Insurance',
  prescription: 'Prescriptions',
  medical_records: 'Medical Records',
  other: 'Other'
};

const CATEGORY_ICONS = {
  lab_results: FileText,
  insurance: FileText,
  prescription: FileText,
  medical_records: FileText,
  other: FileText
};

export default function FileUpload({
  patientId,
  patientName,
  onUploadComplete,
  maxFiles = 5,
  allowedTypes = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'doc', 'docx', 'txt'],
  maxSizeBytes = 10 * 1024 * 1024 // 10MB
}: FileUploadProps) {
  const [uploadingFiles, setUploadingFiles] = useState<UploadingFile[]>([]);
  const [dragActive, setDragActive] = useState(false);

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getFileIcon = (fileName: string) => {
    const extension = fileName.toLowerCase().split('.').pop() || '';
    if (['jpg', 'jpeg', 'png', 'gif'].includes(extension)) {
      return Image;
    }
    return FileText;
  };

  const validateFile = (file: File): string | null => {
    // Check file size
    if (file.size > maxSizeBytes) {
      return `File size exceeds ${formatFileSize(maxSizeBytes)} limit`;
    }

    // Check file type
    const extension = file.name.toLowerCase().split('.').pop() || '';
    if (!allowedTypes.includes(extension)) {
      return `File type not allowed. Supported: ${allowedTypes.join(', ').toUpperCase()}`;
    }

    return null;
  };

  const uploadFile = async (file: File): Promise<UploadedFile> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('patient_id', patientId);
    formData.append('patient_name', patientName);

    const response = await fetch('/api/v1/files/upload', {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Upload failed');
    }

    return response.json();
  };

  const handleFiles = useCallback(async (files: File[]) => {
    if (files.length === 0) return;

    // Validate and filter files
    const validFiles: File[] = [];
    const errors: string[] = [];

    for (const file of files) {
      if (uploadingFiles.length + validFiles.length >= maxFiles) {
        errors.push(`Maximum ${maxFiles} files allowed`);
        break;
      }

      const validationError = validateFile(file);
      if (validationError) {
        errors.push(`${file.name}: ${validationError}`);
      } else {
        validFiles.push(file);
      }
    }

    if (errors.length > 0) {
      alert(errors.join('\n'));
    }

    if (validFiles.length === 0) return;

    // Initialize uploading files
    const newUploadingFiles = validFiles.map(file => ({
      file,
      progress: 0,
      error: undefined,
      success: false
    }));

    setUploadingFiles(prev => [...prev, ...newUploadingFiles]);

    // Upload files
    const uploadedFiles: UploadedFile[] = [];

    for (let i = 0; i < validFiles.length; i++) {
      const file = validFiles[i];
      
      try {
        // Update progress to show upload started
        setUploadingFiles(prev =>
          prev.map(uf => 
            uf.file === file ? { ...uf, progress: 50 } : uf
          )
        );

        const result = await uploadFile(file);
        uploadedFiles.push(result);

        // Mark as successful
        setUploadingFiles(prev =>
          prev.map(uf => 
            uf.file === file ? { ...uf, progress: 100, success: true } : uf
          )
        );

      } catch (error) {
        // Mark as failed
        setUploadingFiles(prev =>
          prev.map(uf => 
            uf.file === file ? { 
              ...uf, 
              error: error instanceof Error ? error.message : 'Upload failed'
            } : uf
          )
        );
      }
    }

    // Call completion callback
    if (uploadedFiles.length > 0 && onUploadComplete) {
      onUploadComplete(uploadedFiles);
    }

    // Clear successful uploads after 3 seconds
    setTimeout(() => {
      setUploadingFiles(prev => prev.filter(uf => !uf.success));
    }, 3000);
  }, [patientId, patientName, maxFiles, maxSizeBytes, allowedTypes, uploadingFiles.length, onUploadComplete]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    const files = Array.from(e.dataTransfer.files);
    handleFiles(files);
  }, [handleFiles]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
  }, []);

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    handleFiles(files);
    // Reset input
    e.target.value = '';
  }, [handleFiles]);

  const removeUploadingFile = (fileToRemove: File) => {
    setUploadingFiles(prev => prev.filter(uf => uf.file !== fileToRemove));
  };

  return (
    <div className="w-full">
      {/* Drop Zone */}
      <div
        className={`
          relative border-2 border-dashed rounded-lg p-8 text-center transition-colors
          ${dragActive 
            ? 'border-blue-400 bg-blue-50' 
            : 'border-gray-300 hover:border-gray-400 bg-gray-50'
          }
        `}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
      >
        <input
          type="file"
          multiple
          accept={allowedTypes.map(type => `.${type}`).join(',')}
          onChange={handleFileSelect}
          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
        />
        
        <Upload className="mx-auto h-12 w-12 text-gray-400 mb-4" />
        <p className="text-lg font-medium text-gray-900 mb-2">
          Drop files here or click to upload
        </p>
        <p className="text-sm text-gray-500">
          Supports: {allowedTypes.join(', ').toUpperCase()} • Max {formatFileSize(maxSizeBytes)} each • Up to {maxFiles} files
        </p>
      </div>

      {/* Uploading Files */}
      {uploadingFiles.length > 0 && (
        <div className="mt-6">
          <h4 className="text-sm font-medium text-gray-900 mb-4">
            Uploading Files ({uploadingFiles.length})
          </h4>
          <div className="space-y-3">
            {uploadingFiles.map((uploadingFile, index) => {
              const FileIcon = getFileIcon(uploadingFile.file.name);
              
              return (
                <div key={index} className="flex items-center p-3 bg-white border rounded-lg shadow-sm">
                  <FileIcon className="h-8 w-8 text-gray-400 flex-shrink-0" />
                  
                  <div className="ml-3 flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {uploadingFile.file.name}
                      </p>
                      <div className="flex items-center ml-2">
                        {uploadingFile.success && (
                          <CheckCircle className="h-5 w-5 text-green-500" />
                        )}
                        {uploadingFile.error && (
                          <AlertCircle className="h-5 w-5 text-red-500" />
                        )}
                        {!uploadingFile.success && !uploadingFile.error && (
                          <button
                            onClick={() => removeUploadingFile(uploadingFile.file)}
                            className="p-1 hover:bg-gray-100 rounded"
                          >
                            <X className="h-4 w-4 text-gray-400" />
                          </button>
                        )}
                      </div>
                    </div>
                    
                    <div className="flex items-center justify-between mt-1">
                      <p className="text-xs text-gray-500">
                        {formatFileSize(uploadingFile.file.size)}
                      </p>
                      {uploadingFile.error && (
                        <p className="text-xs text-red-600">{uploadingFile.error}</p>
                      )}
                    </div>

                    {/* Progress bar */}
                    {!uploadingFile.error && (
                      <div className="w-full bg-gray-200 rounded-full h-1.5 mt-2">
                        <div
                          className={`h-1.5 rounded-full transition-all duration-300 ${
                            uploadingFile.success ? 'bg-green-500' : 'bg-blue-500'
                          }`}
                          style={{ width: `${uploadingFile.progress}%` }}
                        />
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}