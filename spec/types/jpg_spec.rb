require 'mini_exiftool'

require 'types/jpg'

describe Types::JPG do
  describe '#event_time' do
    subject { described_class.new(source_dir, filename, options).event_time }
    let(:source_dir) { './spec/data/' }
    let(:options) { { test_mode: false } }
    let(:exif_datetimeoriginal) { MiniExiftool.new(source_dir + filename)['DateTimeOriginal'] }

    context 'when \'jpg\' file' do
      context 'iPhone via Camera Sync' do
        let(:filename) { 'iPhone - Camera Sync.jpg' }

        it 'should equal \'DateTimeOriginal\' EXIF date' do
          is_expected.to eq exif_datetimeoriginal
        end
      end
      context 'iPhone via USB' do
        let(:filename) { 'iPhone - USB.jpg' }

        it 'should equal \'DateTimeOriginal\' EXIF date' do
          is_expected.to eq exif_datetimeoriginal
        end
      end
      context 'Canon T2i via USB' do
        let(:filename) { 'Canon T2i - USB.jpg' }

        it 'should equal \'DateTimeOriginal\' EXIF date' do
          is_expected.to eq exif_datetimeoriginal
        end
      end
      context 'Canon ELPH via USB' do
        let(:filename) { 'Canon ELPH - USB.jpg' }

        it 'should equal \'DateTimeOriginal\' EXIF date' do
          is_expected.to eq exif_datetimeoriginal
        end
      end
    end
  end
end
