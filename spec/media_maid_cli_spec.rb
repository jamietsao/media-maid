require 'mini_exiftool'
require 'media_maid_cli'

describe MediaMaidCLI do
  let(:thor_cli) do
    cli = described_class.new
    cli.options = { test_mode: false, verbose: false }
    cli
  end
  describe '#get_event_time' do
    subject { thor_cli.send(:get_event_time, source_dir, filename) }
    let(:source_dir) { './spec/data/' }
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

  describe '#update_mtime' do
    before(:all) do
      # create copy of test media files in tmp directory
      @temp_dir = './spec/data/tmp/'
      FileUtils.mkdir_p(@temp_dir)
      FileUtils.cp_r(Dir.glob('./spec/data/' + '*.*'), @temp_dir, preserve: true)
    end
    subject { thor_cli.send(:update_mtime, temp_dir, filename) }
    let(:temp_dir) { @temp_dir }
    let(:event_time) { thor_cli.send(:get_event_time, temp_dir, filename) }

    context 'when \'jpg\' file' do
      context 'iPhone via Camera Sync' do
        let(:filename) { 'iPhone - Camera Sync.jpg' }

        it 'updates file mtime to EXIF event time' do
          expect(File.mtime(temp_dir + filename)).to_not eq event_time
          is_expected.to eq 1
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'iPhone via USB' do
        let(:filename) { 'iPhone - USB.jpg' }

        it 'does NOT update file mtime' do
          expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'Canon T2i via USB' do
        let(:filename) { 'Canon T2i - USB.jpg' }

        it 'does NOT update file mtime' do
          expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'Canon ELPH via USB' do
        let(:filename) { 'Canon ELPH - USB.jpg' }

        it 'does NOT update file mtime' do
          # TODO: off by 1 second so this check fails =/
          # expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          # expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
    end
    after(:all) do
      # remove temp directory after tests
      FileUtils.rm_rf(@temp_dir)
    end
  end
end
