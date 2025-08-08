'use client';

import { useState, useEffect, useCallback } from 'react';
import { FileText, Image, Download, Trash2, Search, Filter, Calendar, User } from 'lucide-react';

interface MedicalFile {
  id: string;
  patient_id: string;
  patient_name: string;
  file_name: string;
  file_type: string;
  file_size: number;
  s3_key: string;
  s3_url?: string;
  category: string;
  uploaded_at: string;
}

interface MedicalFileManagerProps {
  patientId?: string;
  showPatientFilter?: boolean;
  onFileDeleted?: (fileId: string) => void;
}

const CATEGORY_LABELS = {
  lab_results: 'Lab Results',
  insurance: 'Insurance',
  prescription: 'Prescriptions',
  medical_records: 'Medical Records',
  other: 'Other'
};

const CATEGORY_COLORS = {
  lab_results: 'bg-blue-100 text-blue-800',
  insurance: 'bg-green-100 text-green-800',
  prescription: 'bg-purple-100 text-purple-800',
  medical_records: 'bg-amber-100 text-amber-800',
  other: 'bg-gray-100 text-gray-800'
};

export default function MedicalFileManager({ 
  patientId, 
  showPatientFilter = true,
  onFileDeleted 
}: MedicalFileManagerProps) {
  const [files, setFiles] = useState<MedicalFile[]>([]);
  const [filteredFiles, setFilteredFiles] = useState<MedicalFile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('');
  const [patientFilter, setPatientFilter] = useState<string>('');
  const [sortBy, setSortBy] = useState<'date' | 'name' | 'category'>('date');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getFileIcon = (fileName: string, fileType: string) => {
    if (fileType.startsWith('image/')) {
      return Image;
    }
    return FileText;
  };

  const fetchFiles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const params = new URLSearchParams();
      if (patientId) {
        params.set('patient_id', patientId);
      }
      if (categoryFilter) {
        params.set('category', categoryFilter);
      }

      const response = await fetch(`/api/v1/files?${params.toString()}`);
      if (!response.ok) {
        throw new Error('Failed to fetch files');
      }

      const data = await response.json();
      setFiles(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load files');
    } finally {
      setLoading(false);
    }
  }, [patientId, categoryFilter]);

  const deleteFile = async (fileId: string) => {
    if (!confirm('Are you sure you want to delete this file? This action cannot be undone.')) {
      return;
    }

    try {
      const response = await fetch(`/api/v1/files/${fileId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete file');
      }

      // Remove file from state
      setFiles(prev => prev.filter(file => file.id !== fileId));
      
      if (onFileDeleted) {
        onFileDeleted(fileId);
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to delete file');
    }
  };

  const downloadFile = (file: MedicalFile) => {
    if (file.s3_url) {
      const link = document.createElement('a');
      link.href = file.s3_url;
      link.download = file.file_name;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } else {
      alert('Download URL not available. Please refresh and try again.');
    }
  };

  // Filter and sort files
  useEffect(() => {
    let filtered = [...files];

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(file =>
        file.file_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        file.patient_name.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply patient filter
    if (patientFilter && showPatientFilter) {
      filtered = filtered.filter(file =>
        file.patient_name.toLowerCase().includes(patientFilter.toLowerCase())
      );
    }

    // Sort files
    filtered.sort((a, b) => {
      let comparison = 0;
      
      switch (sortBy) {
        case 'date':
          comparison = new Date(a.uploaded_at).getTime() - new Date(b.uploaded_at).getTime();
          break;
        case 'name':
          comparison = a.file_name.localeCompare(b.file_name);
          break;
        case 'category':
          comparison = a.category.localeCompare(b.category);
          break;
      }

      return sortOrder === 'asc' ? comparison : -comparison;
    });

    setFilteredFiles(filtered);
  }, [files, searchTerm, patientFilter, sortBy, sortOrder, showPatientFilter]);

  // Load files on mount and when filters change
  useEffect(() => {
    fetchFiles();
  }, [fetchFiles]);

  // Get unique categories from files
  const availableCategories = Array.from(new Set(files.map(file => file.category)));

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">Loading files...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <p className="text-red-600">{error}</p>
        <button 
          onClick={fetchFiles}
          className="mt-2 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="w-full">
      {/* Filters and Search */}
      <div className="mb-6 space-y-4">
        <div className="flex flex-wrap gap-4">
          {/* Search */}
          <div className="flex-1 min-w-64">
            <div className="relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search files or patients..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Category Filter */}
          <div className="min-w-48">
            <div className="relative">
              <Filter className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none"
              >
                <option value="">All Categories</option>
                {availableCategories.map(category => (
                  <option key={category} value={category}>
                    {CATEGORY_LABELS[category as keyof typeof CATEGORY_LABELS] || category}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Patient Filter */}
          {showPatientFilter && (
            <div className="min-w-48">
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Filter by patient..."
                  value={patientFilter}
                  onChange={(e) => setPatientFilter(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
          )}
        </div>

        {/* Sort Options */}
        <div className="flex items-center gap-4 text-sm">
          <span className="text-gray-600">Sort by:</span>
          <button
            onClick={() => {
              if (sortBy === 'date') {
                setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
              } else {
                setSortBy('date');
                setSortOrder('desc');
              }
            }}
            className={`px-3 py-1 rounded ${sortBy === 'date' ? 'bg-blue-100 text-blue-800' : 'hover:bg-gray-100'}`}
          >
            Date {sortBy === 'date' && (sortOrder === 'asc' ? '↑' : '↓')}
          </button>
          <button
            onClick={() => {
              if (sortBy === 'name') {
                setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
              } else {
                setSortBy('name');
                setSortOrder('asc');
              }
            }}
            className={`px-3 py-1 rounded ${sortBy === 'name' ? 'bg-blue-100 text-blue-800' : 'hover:bg-gray-100'}`}
          >
            Name {sortBy === 'name' && (sortOrder === 'asc' ? '↑' : '↓')}
          </button>
          <button
            onClick={() => {
              if (sortBy === 'category') {
                setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
              } else {
                setSortBy('category');
                setSortOrder('asc');
              }
            }}
            className={`px-3 py-1 rounded ${sortBy === 'category' ? 'bg-blue-100 text-blue-800' : 'hover:bg-gray-100'}`}
          >
            Category {sortBy === 'category' && (sortOrder === 'asc' ? '↑' : '↓')}
          </button>
        </div>
      </div>

      {/* Files List */}
      {filteredFiles.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          <FileText className="mx-auto h-12 w-12 mb-4 opacity-50" />
          <p className="text-lg font-medium">No files found</p>
          <p className="text-sm">
            {files.length === 0 
              ? 'No files have been uploaded yet.' 
              : 'Try adjusting your search or filters.'
            }
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredFiles.map((file) => {
            const FileIcon = getFileIcon(file.file_name, file.file_type);
            
            return (
              <div key={file.id} className="bg-white border rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between">
                  <div className="flex items-center flex-1 min-w-0">
                    <FileIcon className="h-8 w-8 text-gray-400 flex-shrink-0" />
                    
                    <div className="ml-3 flex-1 min-w-0">
                      <div className="flex items-center gap-3">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {file.file_name}
                        </p>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          CATEGORY_COLORS[file.category as keyof typeof CATEGORY_COLORS] || CATEGORY_COLORS.other
                        }`}>
                          {CATEGORY_LABELS[file.category as keyof typeof CATEGORY_LABELS] || file.category}
                        </span>
                      </div>
                      
                      <div className="flex items-center gap-4 mt-1 text-xs text-gray-500">
                        <div className="flex items-center">
                          <Calendar className="h-3 w-3 mr-1" />
                          {formatDate(file.uploaded_at)}
                        </div>
                        <div className="flex items-center">
                          <span>{formatFileSize(file.file_size)}</span>
                        </div>
                        {showPatientFilter && (
                          <div className="flex items-center">
                            <User className="h-3 w-3 mr-1" />
                            {file.patient_name}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      onClick={() => downloadFile(file)}
                      disabled={!file.s3_url}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Download file"
                    >
                      <Download className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => deleteFile(file.id)}
                      className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
                      title="Delete file"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Summary */}
      <div className="mt-6 text-sm text-gray-500 text-center">
        Showing {filteredFiles.length} of {files.length} files
      </div>
    </div>
  );
}